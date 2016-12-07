# frozen_string_literal: true
module Redstruct
  module Collections
    class Strings < Redstruct::Collections::Base
      # Gets the value of all keys.
      # @return [Array<String>, Hash<String, String>] if mapped is false, return in the order of the keys array. if true, returns as a hash of key => value
      def get(mapped: false)
        if mapped
          return self.connection.mapped_mget(*@keys)
        else
          return self.connection.mget(*@keys)
        end
      end

      # Sets the values for all keys.
      # @param [Array<Object>, Hash<String, Object>] values if a hash, assumes format as key => value. if array, assumes order is the same as the keys array
      # @param [Boolean] nx if true, set one or more values, only if none of the keys exist
      def set(values, nx: false)
        if values.is_a?(Hash)
          mapped_set(values, nx: nx)
        else
          ordered_set(values, nx: nx)
        end
      end

      # :nodoc:
      def mapped_set(values, nx: false)
        values = values.each_with_object({}) do |key, value, acc|
          acc[key] = value.to_s
        end

        if nx
          self.connection.mapped_msetnx(values)
        else
          self.connection.mapped_mset(values)
        end
      end
      protected :mapped_set

      # :nodoc:
      def ordered_set(values, nx: false)
        pairs = values.each_with_index.each_with_object([]) do |(value, index), acc|
          acc.push(@keys[index], value)
        end

        if nx
          self.connection.msetnx(*pairs)
        else
          self.connection.mset(*pairs)
        end
      end
      protected :ordered_set
    end
  end
end
