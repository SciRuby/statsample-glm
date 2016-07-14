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

      def model
        @model || fit_model
      end

      def predict(new_data)
        model.predict(df_for_prediction(new_data))
      end

      def df_for_prediction df
        canonicalize_df(df)
      end

      def df_for_regression
        df = canonicalize_df(@df)
        df[@formula.y.value] = @df[@formula.y.value]
        df        
      end

      def canonicalize_df(orig_df)
        tokens = @formula.canonical_tokens
        tokens.shift if tokens.first.value == '1'
        df = tokens.map { |t| t.to_df orig_df }.reduce(&:merge)
        df
      end

      def fit_model
        @opts[:constant] = 1 if @formula.tokens.include? Token.new('1')
        @model = Statsample::GLM.compute(
          df_for_regression,
          @formula.y.value,
          @method,
          @opts
        )
      end
    end
  end
end
