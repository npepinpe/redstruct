# frozen_string_literal: true
module Redstruct
  module Collections
    class Base
      include Redstruct::Utils::Inspectable
      extend Forwardable

      def_delegators :@factory, :connection, :connection

      # @return [String] The keys pointing to the objects part of the collection
      attr_reader :keys

      def initialize(keys:, factory:)
        @factory = factory
        @keys = keys.dup.freeze
      end

      def to_h
        return { keys: @keys }
      end

      # :nocov:
      def inspectable_attributes
        { key: @keys, factory: @factory }
      end
      # :nocov:
    end
  end
end
