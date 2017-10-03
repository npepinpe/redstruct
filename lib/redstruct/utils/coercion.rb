# frozen_string_literal: true

module Redstruct
  module Utils
    # Coercion utilities to map Redis replies to Ruby types, or vice-versa
    module Coercion
      # Coerces the value into an array.
      #   Returns the value if it is already an array (or subclass)
      #   Returns value.to_a if it responds to to_a
      #   Returns [value] otherwise
      # @param [Object] value The value to coerce
      # @return [Array] The coerced value
      def coerce_array(value)
        case value
        when nil then []
        when Array then value
        else
          value.respond_to?(:to_a) ? value.to_a : [value]
        end
      end

      # Coerces an object into a boolean:
      #   If nil or 0 (after .to_i) => false
      #   True otherwise
      # @param [Object] value The object to coerce into a bool
      # @return [Boolean] Coerced value
      def coerce_bool(value)
        case value
        when nil, false then false
        when Numeric then !value.zero?
        else
          true
        end
      end

      # Coerces a value into a timestamp in milliseconds
      # If given an integer, assumes it is a value in seconds.
      # If given a float, assumes it is a value in seconds (with decimals as milliseconds)
      # If given anything else, converts to float or integer, then coerces.
      # If not convertable, returns 0.
      # @return [Integer]
      def coerce_time_milli(value)
        case value
        when Integer then value * 1000
        when Float then (value * 1000).floor
        else
          if value.respond_to?(:to_f)
            coerce_time_milli(value.to_f)
          elsif value.respond_to?(:to_i)
            coerce_time_milli(value.to_i)
          else
            0
          end
        end
      end
    end
  end
end
