module Statsample
  module GLM
    # Class for performing regression
    class Regression
      # Initializes a regression object to fit model using formlua language
      # @param [String] formula formula for creating model
      # @param [Daru::DataFrame] df dataframe to be used for the fitting model
      # @param [Symbol] method method of regression.
      #   For example, :logistic, :normal, etc.
      # @example
      #   df = Daru::DataFrame.from_csv 'spec/data/df.csv'
      #   df.to_category 'c', 'd', 'e'
      #   reg = Statsample::GLM::Regression.new 'y~a+b:c', df, :logistic
      def initialize(formula, df, method, opts = {})
        @formula = FormulaWrapper.new formula, df
        @df = df
        @method = method
        @opts = opts
      end

      # Returns the fitted model
      # @return model associated with regression object obtained by applying
      #   the formula langauge on the given dataframe with given method
      # @example
      #   df = Daru::DataFrame.from_csv 'spec/data/df.csv'
      #   df.to_category 'c', 'd', 'e'
      #   reg = Statsample::GLM::Regression.new 'y~a+b:c', df, :logistic
      #   mod = reg.model
      #   mod.coefficients :hash
      #   # => {:a=>-0.4315113121759436,
      #   # :"c_no:b"=>-0.23438037201383238,
      #   # :"c_yes:b"=>-0.23683973232674818,
      #   # :constant=>16.81450207777355}
      def model
        @model || fit_model
      end

      # Obtain predictions on new data
      # @param [Daru::DataFrame] new_data the data to obtain predictions on
      # @return [Daru::Vector] vector containing predictions for new data
      # @example
      #   df = Daru::DataFrame.from_csv 'spec/data/df.csv'
      #   df.to_category 'c', 'd', 'e'
      #   reg = Statsample::GLM::Regression.new 'y~a+b:c', df, :logistic
      #   reg.predict df.head(3)
      #   # => #<Daru::Vector(3)>
      #   #                   0 0.41834114079218554
      #   #                   1  0.6961349288519916
      #   #                   2  0.9993004245984171
      def predict(new_data)
        model.predict(df_for_prediction(new_data))
      end

      # Returns dataframe obtained through applying the formula
      # on the given dataframe. Its for obtaining predicitons on new data.
      # @param [Daru::DataFrame] df datafraem for which to obtain predicitons
      # @return [Daru::DataFrame] dataframe obtained after applying formula
      # @example
      #   df = Daru::DataFrame.from_csv 'spec/data/df.csv'
      #   df.to_category 'c', 'd', 'e'
      #   reg = Statsample::GLM::Regression.new 'y~a+b:c', df, :logistic
      #   reg.df_for_prediction df.head(3)
      #   # => #<Daru::DataFrame(3x3)>
      #   #               a  c_no:b c_yes:b
      #   #       0       6    62.1     0.0
      #   #       1      18     0.0    34.7
      #   #       2       6    29.7     0.0
      def df_for_prediction(df)
        # TODO: This code can be improved.
        # See https://github.com/v0dro/daru/issues/245
        df = Daru::DataFrame.new(df.to_h,
          order: @df.vectors.to_a & df.vectors.to_a
        )
        df.vectors.each do |vec|
          if @df[vec].category?
            df[vec] = df[vec].to_category
            df[vec].categories = @df[vec].categories
            df[vec].base_category = @df[vec].base_category
          end
        end
        canonicalize_df(df)
      end

      # Returns dataframe obtained through applying formula on the dataframe.
      # Its used for fitting the model.
      # @return [Daru::DataFrame] dataframe obtained after applying formula
      # @example
      #   df = Daru::DataFrame.from_csv 'spec/data/df.csv'
      #   df.to_category 'c', 'd', 'e'
      #   reg = Statsample::GLM::Regression.new 'y~a+b:c', df, :logistic
      #   reg.df_for_regression.head(3)
      #   # => #<Daru::DataFrame(3x4)>
      #   #               a  c_no:b c_yes:b       y
      #   #       0       6    62.1     0.0       0
      #   #       1      18     0.0    34.7       1
      #   #       2       6    29.7     0.0       1
      def df_for_regression
        df = canonicalize_df(@df)
        df[@formula.y.value] = @df[@formula.y.value]
        df
      end

      private

      def canonicalize_df(orig_df)
        tokens = @formula.canonical_tokens
        tokens.shift if tokens.first.value == '1'
        df = tokens.map { |t| t.to_df orig_df }.reduce(&:merge)
        df
      end

      def fit_model
        @opts[:constant] = 1 if
          @formula.canonical_tokens.include? Token.new('1')
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
