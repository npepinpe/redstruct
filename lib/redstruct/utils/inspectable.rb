# frozen_string_literal: true
module Redstruct
  module Utils
    # Adds helper methods for calling #inspect on a custom object
    module Inspectable
      # Generates a human readable list of attributes when inspecting a custom object
      # @return [String]
      def inspect
        attributes = inspectable_attributes.map do |key, value|
          "#{key}: <#{value.inspect}>"
        end

        return "#{self.class.name}: #{attributes.join(', ')}"
      end
      alias to_s inspect

      # To be overloaded by the including class
      # @return [Hash<String, #inspect>] list of attributes that can be seen
      def inspectable_attributes
        {}
      end
    end
  end
end
