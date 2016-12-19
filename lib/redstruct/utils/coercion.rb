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
        return [] if value.nil?
        return value if value.is_a?(Array)
        return value.to_a if value.respond_to?(:to_a)
        return [value]
      end
      module_function :coerce_array

      # Coerces an object into a boolean:
      #   If nil or 0 (after .to_i) => false
      #   True otherwise
      # @param [Object] value The object to coerce into a bool
      # @return [Boolean] Coerced value
      def coerce_bool(value)
        return false if value.nil?
        return false if value.to_i == 0

        return true
      end
      module_function :coerce_bool
    end
  end
end
