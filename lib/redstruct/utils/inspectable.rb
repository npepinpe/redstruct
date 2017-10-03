# frozen_string_literal: true

module Redstruct
  module Utils
    # Adds helper methods for calling #inspect on a custom object
    module Inspectable
      # Generates a human readable list of attributes when inspecting a custom object
      # @return [String]
      def inspect
        attributes = inspectable_attributes.map do |key, value|
          "#{key}: #{value.inspect}"
        end

        address = format('0x%016x', (object_id << 1))
        return "#<#{self.class.name}:#{address} #{attributes.join(', ')}>"
      end

      # To be overloaded by the including class
      # @return [Hash<String, #inspect>] list of attributes that can be seen
      def inspectable_attributes
        {}
      end
    end
  end
end
