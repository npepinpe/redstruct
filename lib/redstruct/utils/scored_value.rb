# frozen_string_literal: true

module Redstruct
  module Utils
    # Small value object to pair a value with its score.
    # Delegates everything to the value, except the compare method (#<=>), which
    # uses the score.
    class ScoredValue < SimpleDelegator
      # @return [String] the value of the item
      attr_reader :value

      # @return [Float] the score of the item
      attr_reader :score

      # @param [#to_s] value the value of the item
      # @param [#to_f] score the score of the item
      def initialize(value:, score:)
        @value = value.to_s
        @score = score.to_f
        super(@value)
      end

      # Uses the score to compare with another ScoredValue
      # @return [Integer] 0 if equal, -1 if less than other.score, 1 if greater
      def <=>(other)
        return @score <=> other.score
      end
    end
  end
end
