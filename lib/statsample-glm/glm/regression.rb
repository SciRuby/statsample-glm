module Statsample
  module GLM
    class Regression
      def initialize formula, df, method, opts={}
        @formula = Formula.new formula
        @df = df
        @method = method
        @opts = opts
      end

      def df_for_regression
        tokens = @formula.parse_formula
        tokens.map { |t| t.to_df @df }.reduce(&:merge)
      end
    end
  end
end