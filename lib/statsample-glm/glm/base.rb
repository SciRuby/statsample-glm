require 'statsample-glm/glm/irls/logistic'
require 'statsample-glm/glm/irls/poisson'
require 'statsample-glm/glm/mle/logistic'
require 'statsample-glm/glm/mle/probit'
require 'statsample-glm/glm/mle/normal'

module Statsample
  module GLM
    class Base

      def initialize ds, y, opts={}
        @opts   = opts
          
        set_default_opts_if_any

        @data_set  = ds.dup(ds.vectors.to_a - [y])
        @dependent = ds[y]

        if @opts[:constant]
          add_constant_vector @opts[:constant]
        else
          add_constant_vector(1) if self.is_a? Statsample::GLM::Normal
        end

        algorithm = @opts[:algorithm].upcase
        method    = @opts[:method].capitalize

        # TODO: Remove this const_get jugaad after 1.9.3 support is removed.

        @regression = Kernel.const_get("Statsample").const_get("GLM")
                            .const_get("#{algorithm}").const_get("#{method}")
                            .new(@data_set, @dependent, @opts)
      end

      # Returns the coefficients of trained model
      #
      # @param [Symbol] as_a Specifies the form of output
      #
      # @return [Vector, Hash, Array] coefficients of the model
      #
      # @example
      #   require 'statsample-glm'
      #   data_set = Daru::DataFrame.from_csv "spec/data/logistic.csv"
      #   glm  = Statsample::GLM.compute data_set, "y", :logistic, {constant: 1}
      #   glm.coefficients as_a = :hash
      #     # =>
      #     # {:x1=>-0.3124937545689041, :x2=>2.286713333462646, :constant=>0.675603176233328}
      #
      def coefficients as_a=:vector
        case as_a
        when :hash
          c = {}
          @data_set.vectors.to_a.each_with_index do |f,i|
            c[f.to_sym] = @regression.coefficients[i]
          end
          c
        when :array
          @regression.coefficients.to_a
        when :vector
          @regression.coefficients
        else
          raise ArgumentError, "as_a has to be one of :array, :hash, or :vector"
        end
      end

      # Returns the standard errors for the coefficient estimates
      #
      # @param [Symbol] as_a Specifies the form of output
      #
      # @return [Vector, Hash, Array] standard error
      #
      # @example
      #   require 'statsample-glm'
      #   data_set = Daru::DataFrame.from_csv "spec/data/logistic.csv"
      #   glm  = Statsample::GLM.compute data_set, "y", :logistic, {constant: 1}
      #   glm.standard_error
      #     # #<Daru::Vector:25594060 @name = nil @metadata = {} @size = 3 >
      #     #                                     nil
      #     #                   0  0.4130813039878828
      #     #                   1  0.7194644911927432
      #     #                   2 0.40380565497038895
      #
      def standard_error as_a=:vector  
        case as_a
        when :hash
          se = {}
          @data_set.vectors.to_a.each_with_index do |f,i|
            se[f.to_sym] = @regression.standard_error[i]
          end
          se
        when :array
          @regression.standard_error.to_a
        when :vector
          @regression.standard_error
        else
          raise ArgumentError, "as_a has to be one of :array, :hash, or :vector"
        end
      end

      def iterations
        @regression.iterations
      end

      # Returns the values predicted by the model
      #
      # @return [Vector] vectors of predicted values
      #
      # @example
      #   require 'statsample-glm'
      #   data_set = Daru::DataFrame.from_csv "spec/data/logistic.csv"
      #   glm  = Statsample::GLM.compute data_set, "y", :logistic, constant: 1
      #   glm.fitted_mean_values
      #     # => 
      #     # #<Daru::Vector:27008600 @name = nil @metadata = {} @size = 50 >
      #     #                                       nil
      #     #                   0  0.18632025624516532
      #     #                   1   0.5146459448198846
      #     #                   2     0.84083523282549
      #     #                   3   0.9241524337773334
      #     #                   4   0.7718528863631826
      #     #                 ...                  ...
      #
      def fitted_mean_values
        @regression.fitted_mean_values
      end

      # Returns the residual for every data point
      #
      # @return [Vector] all residuals in a vector
      #
      # @example
      #   require 'statsample-glm'
      #   data_set = Daru::DataFrame.from_csv "spec/data/logistic.csv"
      #   glm  = Statsample::GLM.compute data_set, "y", :logistic, {constant: 1}
      #   glm.residuals
      #     # #<Daru::Vector:22263420 @name = y @metadata = {} @size = 50 >
      #     #                                         y
      #     #                   0 -0.18632025624516532
      #     #                   1  -0.5146459448198846
      #     #                   2     0.15916476717451
      #     #                   3  -0.9241524337773334
      #     #                   4   0.2281471136368174
      #     #                 ...                  ...
      #
      def residuals
        @regression.residuals
      end

      # Returns the degrees of freedom value.
      #
      # @return [Integer] the degrees of freedom
      #
      # @example
      #   require 'statsample-glm'
      #   data_set = Daru::DataFrame.from_csv "spec/data/logistic.csv"
      #   glm  = Statsample::GLM.compute data_set, "y", :logistic, constant: 1
      #   glm.degree_of_freedom
      #     # => 47
      #
      def degree_of_freedom
        @regression.degree_of_freedom
      end

      # Returns the optimal value of the log-likelihood function when using MLE algorithm.
      # The optimal value is the value of the log-likelihood function at the MLE solution.
      #
      # @return [Numeric] the optimal value of log-likelihood function
      #
      # @example
      #   require 'statsample-glm'
      #   data_set = Daru::DataFrame.from_csv "spec/data/logistic.csv"
      #   glm  = Statsample::GLM.compute data_set, "y", :logistic, constant: 1, algorithm: :mle
      #   glm.log_likelihood
      #     # => -21.4752278175261
      #
      def log_likelihood
        @regression.log_likelihood if @opts[:algorithm] == :mle
      end

      # Use the fitted GLM to obtain predictions on new data.
      #
      # == Arguments 
      #
      # * new_data - a `Daru::DataFrame` containing new observations for the same
      #   variables that were used to fit the model. The vectors must be given
      #   in the same order as in the data frame that was originally used to fit
      #   the model. If `new_data` is not provided, then the original data frame
      #   which was used to fit the model, is used in place of `new_data`.
      #
      # == Returns
      #
      #   A `Daru::Vector` containing the predictions. The predictions are 
      #   computed on the scale of the response variable (for example, for
      #   the logistic regression model, the predictions are probabilities
      #   on logit scale).
      #
      # == Usage
      #
      #   require 'statsample-glm'
      #   data_set = Daru::DataFrame.from_csv "spec/data/logistic.csv"
      #   glm  = Statsample::GLM.compute data_set, "y", :logistic, {constant: 1}
      #   new_data = Daru::DataFrame.new([[0.1, 0.2, 0.3], [-0.1, 0.0, 0.1]],
      #                                  order: ["x1", "x2"])
      #   glm.predict new_data
      #     # => 
      #     # #<Daru::Vector:47155268294500 @name = nil @size = 3 >
      #     #                                   nil
      #     #                  0 0.6024496420392775
      #     #                  1 0.6486486378079906
      #     #                  2 0.6922216620285223
      #
      def predict new_data=nil
        if @opts[:constant] then
          new_data.add_vector :constant, [@opts[:constant]]*new_data.nrows
        end
        # Statsample::GLM::Normal model always has an intercept term, see #initialize
        if self.is_a? Statsample::GLM::Normal then
          new_data.add_vector :constant, [1.0]*new_data.nrows
        end

        @regression.predict new_data
      end

     private

      def set_default_opts_if_any
        @opts[:algorithm]  ||= :irls 
        @opts[:iterations] ||= 100   
        @opts[:epsilon]    ||= 1e-7  
        @opts[:link]       ||= :log  
      end

      def create_vector arr
        Daru::Vector.new(arr)
      end

      def add_constant_vector x=1
        @data_set.add_vector :constant, [x]*@data_set.nrows
      end
    end
  end
end
