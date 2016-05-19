module Statsample
  module GLM
    module IRLS
      class Base

        attr_reader :coefficients, :standard_errors, :iterations, 
          :fitted_mean_values, :residuals, :degrees_of_freedom

        def initialize data_set, dependent, opts={}
          @data_set  = data_set.to_matrix
          @dependent = dependent
          @opts      = opts

          irls
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
        def predict new_data_set=nil
          if new_data_set.nil? then
            @fitted_mean_values
          else
            new_data_matrix = new_data_set.to_matrix
            b               = @coefficients.to_matrix axis=:vertical
            create_vector measurement(new_data_matrix, b).to_a.flatten
          end
        end

       private

        def irls
          max_iter   = @opts[:iterations]
          b          = Matrix.column_vector Array.new(@data_set.column_size,0.0)

          1.upto(max_iter) do
            intermediate = (hessian(@data_set,b).inverse * 
                            jacobian(@data_set, b, @dependent))
            b_new        = b - intermediate

            if((b_new - b).map(&:abs)).to_a.flatten.inject(:+) < @opts[:epsilon]
              b = b_new
              break
            end
            b = b_new
          end

          @coefficients       = create_vector(b.column_vectors[0])
          @iterations         = max_iter
          @standard_errors     = create_vector(hessian(@data_set,b).inverse
                                                                  .diagonal
                                                                  .map{ |x| -x}
                                                                  .map{ |y| Math.sqrt(y) })
          @fitted_mean_values = create_vector measurement(@data_set,b).to_a.flatten
          @residuals          = @dependent - @fitted_mean_values
          @degrees_of_freedom  = @dependent.count - @data_set.column_size
        end

        def create_vector arr
          Daru::Vector.new(arr)
        end
      end
    end
  end
end
