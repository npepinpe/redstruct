module Redstruct
  module Types
    class Counter < Redstruct::Types::String
      include Redstruct::Utils::Scriptable

      def initialize(increment: 1, max: nil, **options)
        super(**options)
        @increment = increment
        @max = max
      end

      def get
        super.to_i
      end

      def set(value)
        super(value.to_i)
      end

      def increment(by: nil, max: nil)
        by ||= @increment
        max ||= @max

        value = if max.nil?
          self.connection.incrby(@key, by.to_i).to_i
        else
          ring_increment_script(keys: @key, argv: [by.to_i, max.to_i]).to_i
        end

        return value
      end

      def decrement(by: nil, max: nil)
        by ||= @increment
        by = -by.to_i
        return increment(by: by, max: max)
      end

      def getset(value)
        return super(value.to_i).to_i
      end

      # @!group Lua Scripts

      defscript :ring_increment_script, <<~LUA
        local by = tonumber(ARGV[1])
        local max = tonumber(ARGV[2])
        local current = redis.call('get', KEYS[1])
        local value = current and tonumber(current) or 0

        value = (value + by) % max
        redis.call('set', KEYS[1], value)

        return value
      LUA

      # @!endgroup

      # Helper method for easy inspection
      def inspectable_attributes
        super.merge(max: @max, increment: @increment)
      end
    end
  end
end
