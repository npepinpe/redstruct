# frozen_string_literal: true

require 'forwardable'
require 'redstruct/factory/object'
require 'redstruct/utils/scriptable'
require 'redstruct/utils/coercion'

module Redstruct
  # Models a basic time series data structure.
  class TimeSeries < Redstruct::Factory::Object
    include Redstruct::Utils::Scriptable
    include Redstruct::Utils::Coercion
    extend Forwardable

    # @return [Float] event expiry in second; after it has expired, events are removed
    attr_reader :event_expiry

    # TODO: Delegate Struct methods to @event_list

    def initialize(id, event_expiry: 0, **options)
      super(**options)

      @id = id
      factory = @factory.factory(@id)
      @event_list = factory.sorted_set('events')

      self.event_expiry = event_expiry
    end

    # Delegates expire call to the underlying sorted set
    def expire(value)
      return @event_list.expire(value)
    end

    # Sets how much time should an event live (shared across all events)
    # This will trigger a cleanup, so events saved without an expiry,
    # or with a different expiry, might now expire
    # @param [#to_f] value the new event expiry value
    def event_expiry=(value)
      @event_expiry = coerce_time_milli(value)
      cleanup_expired_events
    end

    # Forces a cleanup of expired events
    def cleanup_expired_events
      cleanup_script(keys: @event_list.key, argv: expires_at)
    end

    # @param [#to_s] event the event to record
    # @return [Integer]
    def add(*events, at: Time.now)
      at = coerce_time_milli(at)
      argv = [@event_expiry]
      events.each do |event|
        argv.push(at, prepend_event_id(event))
      end

      return add_script(keys: @event_list.key, argv: argv)
    end

    # Returns data points from within a given time range.
    # @param [Hash] options
    # @option options [Time] :before optional upper bound to select events (inclusive)
    # @option options [Time] :after optional lower bound to select events (inclusive)
    # @option options [Range<Time>] :in optional range of time to select events (has priority over after/before)
    # @option options [Integer] :limit maximum number of events to return
    # @option options [Integer] :offset offset in the list (use in conjunction with limit for pagination)
    def get(options = {})
      lower = nil
      upper = nil

      if options[:in].nil?
        lower = options[:after].nil? ? '-inf' : coerce_time_milli(options[:after])
        upper = options[:before].nil? ? '+inf' : [0, coerce_time_milli(options[:before])].max
      else
        lower = coerce_time_milli(options[:in].begin)
        upper = coerce_time_milli(options[:in].end)
        upper = "(#{upper}" if options[:in].exclude_end?
      end

      argv = [expires_at, lower, upper]

      unless options[:limit].nil?
        limit = options[:limit].to_i
        raise ArgumentError, 'limit must be positive' unless limit.positive?
        argv.push(limit, [0, options[:offset].to_i].max)
      end

      events = get_script(keys: @event_list.key, argv: argv)
      return events.map(&method(:remove_event_id))
    end

    protected

    def expires_at
      return coerce_time_milli(Time.now) - @event_expiry
    end

    def prepend_event_id(event)
      # add a UUID to ensure the event is unique
      event_id = SecureRandom.uuid.tr('-', '')
      return "#{event_id}#{event}"
    end

    def remove_event_id(event)
      # UUIDs are exactly 32 chars (without dashes)
      return event[32..-1]
    end

    # @!group Lua Scripts

    defscript :cleanup_script, <<~LUA
      local event_expiry = tonumber(table.remove(ARGV, 1))

      if event_expiry > 0 then
        redis.call('zremrangebyscore', KEYS[1], '-inf', event_expiry)
      end
    LUA

    defscript :get_script, <<~LUA
      #{SCRIPT_CLEANUP_SCRIPT[:script]}

      local lower = tonumber(ARGV[1])
      local upper = tonumber(ARGV[2])
      local query = { lower, upper }

      if table.getn(ARGV) > 2 then
        query[2] = 'LIMIT'
        query[3] = tonumber(ARGV[3])
        query[4] = tonumber(ARGV[4])
      end

      return redis.call('zrangebyscore', KEYS[1], unpack(query))
    LUA

    # TODO: Debate whether or not to perform cleanup in the ADD method
    defscript :add_script, <<~LUA
      #{SCRIPT_CLEANUP_SCRIPT[:script]}
      return redis.call('zadd', KEYS[1], unpack(ARGV))
    LUA

    # @!endgroup
  end
end
