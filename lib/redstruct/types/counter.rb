module Redstruct
  module Types
    class Counter < Redstruct::Types::String
      include Redstruct::Utils::Scriptable

      def initialize(increment: 1, max: nil, **options)
        super(**options)
        @increment = increment
        @max = max
      end

      def transform_write_value(value)
        return value.to_i
      end
      protected :transform_write_value

      def transform_read_value(value)
        return value.to_i
      end
      protected :transform_read_value

      def increment(by: nil, max: nil)
        by ||= transform_write_value(@increment)
        max ||= transform_write_value(@max)

        value = if max.nil?
          self.connection.incrby(@key, by)
        else
          ring_increment_script(keys: @key, argv: [by, max.to_i]).to_i
        end

        return transform_read_value(value)
      end

      def decrement(by: nil, max: nil)
        by ||= transform_read_value(@increment)
        return increment(by: -by, max: max)
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
