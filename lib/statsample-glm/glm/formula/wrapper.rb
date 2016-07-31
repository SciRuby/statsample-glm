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
        formula = formula.gsub(/\s+/, '')
        lhs, rhs = split_lhs_rhs formula
        @y = Token(lhs)
        @tokens = split_to_tokens reduce_formula(rhs)
        @tokens = @tokens.uniq.sort
        manage_constant_term
        @canonical_tokens = non_redundant_tokens
      end

      def split_lhs_rhs(expr)
        expr.split '~'
      end

      def reduce_formula(expr)
        # Split the expression to array
        expr = expr.split %r{(?=[+*/:()])|(?<=[+*/:()])}
        # Convert infix exp to postfix exp
        postfix_expr = to_postfix expr
        # Evaluate the expression
        eval_postfix postfix_expr
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

      def to_s
        "#{@y}~#{@tokens.join '+'}"
      end

      private

      TOKEN_0 = Token.new '0'
      TOKEN_1 = Token.new '1'
      def Token(val, full = true) # rubocop:disable Style/MethodName
        return TOKEN_0 if val == '0'
        return TOKEN_1 if val == '1'
        Token.new(val, full)
      end

      # Removes intercept token if term '0' is found in the formula.
      # Intercept token remains if term '1' is found.
      # If neither term '0' nor term '1' is found then,
      # intercept token is added.
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
      # @param [Statsample::GLM::Token] token to extract numeric terms from
      # @return [Array] array of numericl terms
      def extract_numeric(token)
        terms = token.interact_terms
        return [] if terms == ['1']
        terms.reject { |t| @df[t].category? }
      end

      def split_to_tokens(formula)
        formula.split('+').map { |t| Token(t) }
      end

      # ==========BEGIN==========
      # Helpers for reduce_formula
      PRIORITY = %w(+ * / :).freeze
      def priority_le?(op1, op2)
        return false unless PRIORITY.include? op2
        PRIORITY.index(op1) <= PRIORITY.index(op2)
      end

      # to_postfix 'a+b' gives 'ab+'
      def to_postfix(expr) # rubocop:disable Metrics/MethodLength
        res_exp = []
        stack = ['(']
        expr << ')'
        expr.each do |s|
          if s == '('
            stack.push '('
          elsif PRIORITY.include? s
            res_exp << stack.pop while priority_le?(s, stack.last)
            stack.push s
          elsif s == ')'
            res_exp << stack.pop until stack.last == '('
            stack.pop
          else
            res_exp << s
          end
        end
        res_exp
      end

      # eval_postfix 'ab*' gives 'a+b+a:b'
      def eval_postfix(expr)
        # Scan through each symbol
        stack = []
        expr.each do |s|
          if PRIORITY.include? s
            y = stack.pop
            x = stack.pop
            stack << apply_operation(s, x, y)
          else
            stack.push s
          end
        end
        stack.pop
      end

      def apply_interact_op(x, y)
        x = x.split('+').to_a
        y = y.split('+').to_a
        terms = x.product(y)
        terms.map! { |term| "#{term[0]}:#{term[1]}" }
        terms.join '+'
      end

      def apply_operation(op, x, y)
        case op
        when '+'
          [x, y].join op
        when ':'
          apply_interact_op x, y
        when '*'
          [x, y, apply_interact_op(x, y)].join '+'
        when '/'
          [x, apply_interact_op(x, y)].join '+'
        else
          raise ArgumentError, "Invalid operation #{op}."
        end
      end
      #==========END==========
    end
  end
end
