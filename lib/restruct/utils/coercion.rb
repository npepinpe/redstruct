module Restruct
  module Utils
    # Coercion utilities to map Redis replies to Ruby types, or vice-versa
    module Coercion
      def coerce_array(value)
        return [] if value.nil?
        return value if value.is_a?(Array)
        return value.to_a if value.respond_to?(:to_a)
        return [value]
      end

      def coerce_bool(value)
        return false if value.nil?
        return false if value.to_i == 0

        return true
      end
    end
  end
end
