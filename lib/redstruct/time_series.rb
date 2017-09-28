# frozen_string_literal: true

require 'redstruct/factory/object'
require 'redstruct/utils/scriptable'
require 'redstruct/utils/coercion'

module Redstruct
  class TimeSeries < Redstruct::Factory::Object
    include Redstruct::Utils::Scriptable
    include Redstruct::Utils::Coercion

    # @return [Float] expiry of the time series in general in seconds
    attr_reader :expiry

    # @return [Float] event expiry in second; after it has expired, events are removed
    attr_reader :event_expiry

    def initialize(id, expiry: 0, event_expiry: 0, **options)
      super(**options)

      @id = id
      factory = @factory.factory(@id)
      @event_list = factory.sorted_set('event_list')
      @event_data = factory.hashmap('event_data')

      self.expiry = expiry
      self.event_expiry = event_expiry
    end

    # @param [#to_f] value the new key expiry value (expires the whole timeseries)
    def expiry=(value)
      @expiry = format_timestamp(value)
      [@event_list, @event_data].each { |object| object.expire(value) }
    end

    # Sets how much time should an event live (shared across all events)
    # This will trigger a cleanup, so events saved without an expiry,
    # or with a different expiry, might now expire
    # @param [#to_f] value the new event expiry value
    def event_expiry=(value)
      @event_expiry = format_timestamp(value)
      cleanup_expired_events
    end

    # Forces a cleanup of expired events
    def cleanup_expired_events
      cleanup_script(keys: keys, argv: expires_at)
    end

    # @param [#to_s] event the event to record
    # @return [Integer]
    def add(*events, at: Time.now)
      at = format_timestamp(at)
      argv = [expires_at, at]
      events.each do |event|
        argv.push(SecureRandom.uuid)
        argv.push(event.to_s)
      end

      return add_script(keys: keys, argv: argv)
    end

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
        lower = options[:after].nil? ? '-inf' : format_timestamp(options[:after])
        upper = options[:before].nil? ? '+inf' : [0, format_timestamp(options[:before])].max
      else
        lower = format_timestamp(options[:in].begin)
        upper = format_timestamp(options[:in].end)
        upper = "(#{upper}" if options[:in].exclude_end?
      end

      argv = [expires_at, lower, upper]

      unless options[:limit].nil?
        limit = options[:limit].to_i
        raise ArgumentError, 'limit must be positive' unless limit.positive?
        argv.push(limit, [0, options[:offset].to_i].max)
      end

      get_script(keys: keys, argv: argv)
    end

    private

    def keys
      return [@event_list.key, @event_data.key]
    end

    def format_timestamp(time)
      return (time.to_f * 1000).to_i
    end

    def expires_at
      return format_timestamp(Time.now) - @event_expiry
    end

    defscript :cleanup_script, <<~LUA
      local event_expiry = tonumber(table.remove(ARGV, 1))

      if event_expiry > 0 then
        local toremove = redis.call('zrangebyscore', KEYS[1], '-inf', event_expiry)

        if table.getn(toremove) > 0 then
          redis.call('hdel', KEYS[2], unpack(toremove))
          redis.call('zremrangebyscore', KEYS[1], '-inf', event_expiry)
        end
      end
    LUA

    defscript :get_script, <<~LUA
      #{SCRIPT_CLEANUP_SCRIPT[:script]}

      local lower = tonumber(ARGV[1])
      local upper = tonumber(ARGV[2])
      local query = { lower, upper }
      local event_ids = {}
      local events = {}

      if table.getn(ARGV) > 2 then
        query[2] = 'LIMIT'
        query[3] = tonumber(ARGV[3])
        query[4] = tonumber(ARGV[4])
      end

      event_ids = redis.call('zrangebyscore', KEYS[1], unpack(query))
      if table.getn(event_ids) > 0 then
        events = redis.call('hmget', KEYS[2], unpack(event_ids))
      end

      return events
    LUA

    defscript :add_script, <<~LUA
      #{SCRIPT_CLEANUP_SCRIPT[:script]}

      local time = tonumber(table.remove(ARGV, 1))
      local result = 0

      for i = 1, table.getn(ARGV), 2 do
        local event_id = ARGV[i]
        local event = ARGV[i+1]

        result = result + redis.call('zadd', KEYS[1], time, event_id)
        redis.call('hset', KEYS[2], event_id, event)
      end

      return result
    LUA
  end
end
