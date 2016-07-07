module Statsample
  module GLM
    class Formula
      def initialize formula
        # @y store the LHS term that is name of vector to be predicted
        # @tokens store the RHS terms of the formula
        @y, @tokens = split_to_tokens(formula)
        @tokens = @tokens.unique.sort
        add_contant_term_if_required
      end

      def parse_formula
        @tokens.inject([]) do |token, acc|
          acc += add_non_redundant_elements token, acc
          acc
        end
      end

      private

      def add_contant_term_if_required
        # TODO: Add support for constants
        @tokens.unshift Token.new(1)
      end

      def add_non_redundant_elements token, result_so_far
        tokens = token.expand
        result_values = result_so_far.map { |t| t.values }
        tokens.reject! { |t| result_values.include? t }
      end

      def split_to_tokens formula
        formula..gsub /\s+/, ''
        lhs_term, rhs = formula.split '~'
        rhs_terms = rhs.split '+'
        (lhs_term + rhs_terms).map { |t| Token.new t }
      end
    end

    class Token
    end
  end
end