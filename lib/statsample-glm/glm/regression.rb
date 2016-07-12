module Statsample
  module GLM
    # Class for performing regression
    class Regression
      def initialize(df, formula, method, opts = {})
        @formula = FormulaWrapper.new formula
        @df = df
        @method = method
        @opts = opts
      end

      def df_for_regression
        tokens = @formula.parse_formula
        tokens.shift if tokens.first.value == '1'
        df = tokens.map { |t| t.to_df @df }.reduce(&:merge)
        # TODO: To be removed after this bug is resolved
        # https://github.com/v0dro/daru/issues/183
        old_names = df.vectors.to_a
        old_names.each { |n| df[n.to_s] = df[n] }
        df.delete_vectors(*old_names)
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
