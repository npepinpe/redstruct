# frozen_string_literal: true
module Redstruct
  module Utils
    module Inspectable
      def inspect
        attributes = inspectable_attributes.map do |key, value|
          "#{key}: <#{value.inspect}>"
        end

        return "#{self.class.name}: #{attributes.join(', ')}"
      end

      def inspectable_attributes
        {}
      end

      def to_s
        return inspect
      end
    end
  end
end
