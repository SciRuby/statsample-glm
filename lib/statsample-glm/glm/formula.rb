module Statsample
  module GLM
    attr_reader :tokens, :y
    class Formula
      def initialize formula
        # @y store the LHS term that is name of vector to be predicted
        # @tokens store the RHS terms of the formula
        @y, *@tokens = split_to_tokens(formula)
        @tokens = @tokens.uniq.sort
        add_contant_term_if_required
      end

      def parse_formula form=:token
        tokens = @tokens.inject([]) do |acc, token|
          acc + add_non_redundant_elements(token, acc)
        end
        case form
        when :token
          tokens
        when :string
          tokens.map { |i| i.to_s }.join '+'
        else
          raise ArgumentError, 'Invalid form option'
        end
      end

      private

      def add_contant_term_if_required
        # TODO: Add support for constants
        @tokens.unshift Token.new(1)
      end

      def add_non_redundant_elements token, result_so_far
        return [token] if token.value == 1
        tokens = token.expand
        result_so_far = result_so_far.map { |t| t.expand }.flatten.uniq
        tokens = tokens - result_so_far
        contract_if_possible tokens
      end

      def split_to_tokens formula
        formula.gsub!(/\s+/, '')
        lhs_term, rhs = formula.split '~'
        rhs_terms = rhs.split '+'
        ([lhs_term] + rhs_terms).map { |t| Token.new t }
      end

      def contract_if_possible tokens
        tokens.combination(2).each do |a, b|
          result = a.add b
          if result
            tokens.delete a
            tokens.delete b
            tokens << result
            return contract_if_possible tokens
          end
        end
        tokens.sort
      end
    end

    class Token
      attr_reader :value, :full
      def initialize value, full=nil
        @value = value
        @full = full.nil? ? guess_full : full
      end

      def interact_terms
        if value.include? ':'
          value.split(':')
        else
          value
        end
      end

      def size
        if value == 1
          0
        else
          value.split(':').size
        end
      end

      def add other
        # ANYTHING + FACTOR- : ANYTHING = FACTOR : ANYTHING
        # ANYTHING + ANYTHING : FACTOR- = ANYTHING : FACTOR
        if size > other.size
          other.add self
        elsif other.size == 2 &&
          size == 1 &&
          other.interact_terms.last == value &&
          other.full.last == full &&
          other.full.first == false
          Token.new "#{other.interact_terms.first}:#{value}", [true, other.full.last]
        elsif other.size == 2 &&
          size == 1 &&
          other.interact_terms.first == value &&
          other.full.first == full &&
          other.full.last == false
          Token.new "#{value}:#{other.interact_terms.last}", [other.full.first, true]
        else
          nil
        end
      end

      def == other
        value == other.value &&
          full == other.full
      end

      def eql? other
        self.==(other)
      end

      def hash
        self.value.hash ^ self.full.hash
      end

      def <=> other
        size <=> other.size
      end

      def to_s
        case size
        when 0
          value
        when 1
          if full == true
            value
          else
            value + '(-)'
          end
        when 2
          a, b = interact_terms
          case full
          when [true, true]
            a + ':' + b
          when [false, true]
            "#{a}(-):#{b}"
          when [true, false]
            "#{a}:#{b}(-)"
          when [false, false]
            "#{a}(-):#{b}(-)"
          end
        end
      end

      def expand
        if size == 0
          [self]
        elsif size == 1
          [Token.new(1), Token.new(value, false)]
        elsif size == 2
          a, b = interact_terms
          [Token.new(a, full=false), Token.new(b, full=false),
           Token.new(a+':'+b, full=[false, false])]
        end
      end

      def to_df df
        if size == 1
          if df[value].category?
            # TODO: Message for me (lokeshh).
            # To be removed and instead create an PR in Daru.
            # Change base category automatically when reordering
            # and replace full: true with true or full=true
            df[value].contrast_code full: full
          else
            Daru::DataFrame.new({value => df[value].to_a})
          end
        elsif size == 2
          case interact_terms.map { |t| df[t].category? }
          when [true, true]
            df.interact_code(interact_terms, full)
          when [false, false]
            Daru::DataFrame.new({
              value => (df[interact_terms.first]*df[interact_terms.last]).to_a
            })
          when [true, false]
            a, b = interact_terms
            Daru::DataFrame.new(
              df[a].contrast_code(full: full.first)
                .map { |dv| ["#{dv.name}:#{b}", (dv*df[b]).to_a] }
                .to_h
            )
          when [false, true]
            a, b = interact_terms
            Daru::DataFrame.new(
              df[b].contrast_code(full: full.last)
                .map { |dv| ["#{a}:#{dv.name}", (dv*df[a]).to_a] }
                .to_h
            )
          end
        end
      end

      private

      def guess_full
        if size == 1
          true
        elsif size == 2
          [true, true]
        end
      end
    end
  end
end