module Statsample
  module GLM
    class Regression
      def initialize df, formula, method, opts={}
        @formula = Formula.new formula
        @df = df
        @method = method
        @opts = opts
      end

      def df_for_regression
        tokens = @formula.parse_formula
        df = tokens[1..-1].map { |t| t.to_df @df }.reduce(&:merge)
        # TODO: To be removed after this bug is resolved
        # https://github.com/v0dro/daru/issues/183
        old_names = df.vectors.to_a
        old_names.each { |n| df[n.to_s] = df[n] }
        df.delete_vectors(*old_names)
        df
      end
    end
  end
end