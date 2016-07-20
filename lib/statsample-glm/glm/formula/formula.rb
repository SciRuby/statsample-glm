module Statsample
  module GLM
    # To process formula language
    class Formula
      attr_reader :tokens, :canonical_tokens

      def initialize(tokens)
        @tokens = tokens
        @canonical_tokens = parse_formula
      end

      def canonical_to_s
        canonical_tokens.join '+'
      end

      # private
      # TODO: Uncomment private after debuggin

      def parse_formula
        @tokens.inject([]) do |acc, token|
          acc + add_non_redundant_elements(token, acc)
        end
      end

      def add_non_redundant_elements(token, result_so_far)
        return [token] if token.value == '1'
        tokens = token.expand
        result_so_far = result_so_far.flat_map(&:expand)
        tokens -= result_so_far
        contract_if_possible tokens
      end

      def contract_if_possible(tokens)
        tokens.combination(2).each do |a, b|
          result = a.add b
          next unless result
          tokens.delete a
          tokens.delete b
          tokens << result
          return contract_if_possible tokens
        end
        tokens.sort
      end
    end
  end
end
