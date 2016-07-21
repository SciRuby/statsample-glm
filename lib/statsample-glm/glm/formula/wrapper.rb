require_relative 'token'

module Statsample
  module GLM
    # This class recognizes what terms are numeric
    # and accordingly forms groups which are fed to Formula
    # Once they are parsed with Formula, they are combined back
    class FormulaWrapper
      attr_reader :tokens, :y, :canonical_tokens

      # Initializes formula wrapper object to parse a given formula into
      # some tokens which do not overlap one another.
      # @note Specify 0 as a term in the formula if you do not want constant
      #   to be included in the parsed formula
      # @param [string] formula to parse
      # @param [Daru::DataFrame] df dataframe requried to know what vectors
      #   are numerical
      # @example
      #   df = Daru::DataFrame.from_csv 'spec/data/df.csv'
      #   df.to_category 'c', 'd', 'e'
      #   formula = Statsample::GLM::FormulaWrapper.new 'y~a+d:c', df
      #   formula.canonical_to_s
      #   #=> "1+c(-)+d(-):c+a"
      def initialize(formula, df)
        @df = df
        # @y store the LHS term that is name of vector to be predicted
        # @tokens store the RHS terms of the formula
        @y, *@tokens = split_to_tokens(formula)
        @tokens = @tokens.uniq.sort
        manage_constant_term
        @canonical_tokens = non_redundant_tokens
      end

      def reduce_formula
        # TODO:
      end

      # Returns canonical tokens in a readable form.
      # @return [String] canonical tokens in a readable form.
      # @note 'y~a+b(-)' means 'a' exist in full rank expansion
      #   and 'b(-)' exist in reduced rank expansion
      # @example
      #   df = Daru::DataFrame.from_csv 'spec/data/df.csv'
      #   df.to_category 'c', 'd', 'e'
      #   formula = Statsample::GLM::FormulaWrapper.new 'y~a+d:c', df
      #   formula.canonical_to_s
      #   #=> "1+c(-)+d(-):c+a"
      def canonical_to_s
        canonical_tokens.join '+'
      end

      # Returns tokens to produce non-redundant design matrix
      # @return [Array] array of tokens that do not produce redundant matrix
      def non_redundant_tokens
        groups = split_to_groups
        # TODO: An enhancement
        # Right now x:c appears as c:x
        groups.each { |k, v| groups[k] = strip_numeric v, k }
        groups.each { |k, v| groups[k] = Formula.new(v).canonical_tokens }
        groups.flat_map { |k, v| add_numeric v, k }
      end

      private

      TOKEN_0 = Token.new '0'
      TOKEN_1 = Token.new '1'
      def Token val, full=true
        return TOKEN_0 if val == '0'
        return TOKEN_1 if val == '1'
        Token.new(val, full)
      end

      # Removes intercept token if term '0' is found in the formula.
      # Intercept token remains if term '1' is found.
      # If neither term '0' nor term '1' is found then, intercept token is added.
      def manage_constant_term
        @tokens.unshift Token('1') unless
          @tokens.include?(Token('1')) ||
          @tokens.include?(Token('0'))
        @tokens.delete Token('0')
      end

      # Groups the tokens to gropus based on the numerical terms
      # they are interacting with.
      def split_to_groups
        @tokens.group_by { |t| extract_numeric t }
      end

      # Add numeric interaction term which was removed earlier
      # @param [Array] tokens tokens on which to add numerical terms
      # @param [Array] numeric array of numeric terms to add
      def add_numeric(tokens, numeric)
        tokens.map do |t|
          terms = t.interact_terms + numeric
          if terms == ['1']
            Token('1')
          else
            terms = terms.reject { |i| i == '1' }
            Token(terms.join(':'), t.full)
          end
        end
      end

      # Strip numerical interacting terms
      # @param [Array] tokens tokens from which to strip numeric
      # @param [Array] numeric array of numeric terms to strip from tokens
      # @return [Array] array of tokens with striped numerical terms
      def strip_numeric(tokens, numeric)
        tokens.map do |t|
          terms = t.interact_terms - numeric
          terms = ['1'] if terms.empty?
          Token(terms.join(':'))
        end
      end

      # Extract numeric interacting terms
      # @param [Statsample::GLM::Token] token form which to extract numeric terms
      # @return [Array] array of numericl terms
      def extract_numeric(token)
        terms = token.interact_terms
        return [] if terms == ['1']
        terms.reject { |t| @df[t].category? }
      end

      def split_to_tokens(formula)
        formula = formula.gsub(/\s+/, '')
        lhs_term, rhs = formula.split '~'
        rhs_terms = rhs.split '+'
        ([lhs_term] + rhs_terms).map { |t| Token(t) }
      end
    end    
  end
end