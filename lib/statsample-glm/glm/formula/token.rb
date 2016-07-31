module Statsample
  module GLM
    # To encapsulate interaction as well as non-interaction terms
    class Token
      attr_reader :value, :full, :interact_terms

      def initialize(value, full = true)
        @interact_terms = value.include?(':') ? value.split(':') : [value]
        @full = coerce_full full
      end

      def value
        interact_terms.join(':')
      end

      def size
        # TODO: Return size 1 for value '1' also
        # CAn't do this at the moment because have to make
        # changes in sorting first
        value == '1' ? 0 : interact_terms.size
      end

      def condition_1?(other)
        # 1: ANYTHING + FACTOR- : ANYTHING = FACTOR : ANYTHING
        other.size == 2 &&
          size == 1 &&
          other.interact_terms.last == value &&
          other.full.last == full.first &&
          other.full.first == false
      end

      def condition_2?(other)
        # 2: ANYTHING + ANYTHING : FACTOR- = ANYTHING : FACTOR
        other.size == 2 &&
          size == 1 &&
          other.interact_terms.first == value &&
          other.full.first == full.first &&
          other.full.last == false
      end

      def add(other) # rubocop:disable Metrics/AbcSize
        # 1: ANYTHING + FACTOR- : ANYTHING = FACTOR : ANYTHING
        # 2: ANYTHING + ANYTHING : FACTOR- = ANYTHING : FACTOR
        if size > other.size
          other.add self

        elsif condition_1? other
          Token.new(
            "#{other.interact_terms.first}:#{value}",
            [true, other.full.last]
          )

        elsif condition_2? other
          Token.new(
            "#{value}:#{other.interact_terms.last}",
            [other.full.first, true]
          )

        elsif value == '1' && other.size == 1
          Token.new(other.value, true)
        end
      end

      def ==(other)
        value == other.value &&
          full == other.full
      end

      alias eql? ==

      def hash
        value.hash ^ full.hash
      end

      def <=>(other)
        size <=> other.size
      end

      def to_s
        interact_terms
          .zip(full)
          .map { |t, f| f ? t : t + '(-)' }
          .join ':'
      end

      def expand
        case size
        when 0
          [self]
        when 1
          [Token.new('1'), Token.new(value, false)]
        when 2
          a, b = interact_terms
          [Token.new('1'), Token.new(a, false), Token.new(b, false),
           Token.new(a + ':' + b, [false, false])]
        end
      end

      def to_df(df)
        case size
        when 1
          if df[value].category?
            df[value].contrast_code full: full.first
          else
            Daru::DataFrame.new value => df[value].to_a
          end
        when 2
          to_df_when_interaction(df)
        end
      end

      private

      def coerce_full(value)
        if value.is_a? Array
          value + Array.new((@interact_terms.size - value.size), true)
        else
          [value] * @interact_terms.size
        end
      end

      def to_df_when_interaction(df)
        case interact_terms.map { |t| df[t].category? }
        when [true, true]
          df.interact_code(interact_terms, full)
        when [false, false]
          to_df_numeric_interact_with_numeric df
        when [true, false]
          to_df_category_interact_with_numeric df
        when [false, true]
          to_df_numeric_interact_with_category df
        end
      end

      def to_df_numeric_interact_with_numeric(df)
        Daru::DataFrame.new value => (df[interact_terms.first] *
          df[interact_terms.last]).to_a
      end

      def to_df_category_interact_with_numeric(df)
        a, b = interact_terms
        Daru::DataFrame.new(
          df[a].contrast_code(full: full.first)
            .map { |dv| ["#{dv.name}:#{b}", (dv * df[b]).to_a] }
            .to_h
        )
      end

      def to_df_numeric_interact_with_category(df)
        a, b = interact_terms
        Daru::DataFrame.new(
          df[b].contrast_code(full: full.last)
            .map { |dv| ["#{a}:#{dv.name}", (dv * df[a]).to_a] }
            .to_h
        )
      end
    end
  end
end
