module Statsample
  module GLM
    # Class for performing regression
    class Regression
      def initialize(formula, df, method, opts = {})
        @formula = FormulaWrapper.new formula, df
        @df = df
        @method = method
        @opts = opts
      end

      def df_for_regression
        tokens = @formula.canonical_tokens
        tokens.shift if tokens.first.value == '1'
        df = tokens.map { |t| t.to_df @df }.reduce(&:merge)

        df[@formula.y.value] = @df[@formula.y.value]
        df
      end

      def fit_model
        Statsample::GLM.compute(
          df_for_regression,
          @formula.y.value,
          @method,
          constant: (1 if @formula.tokens.include? Token.new('1'))
        )
      end
    end
  end
end
