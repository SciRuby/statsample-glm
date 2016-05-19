require 'spec_helper.rb'

describe Statsample::GLM::Logistic do
  context "IRLS algorithm" do
    before do
      @data_set = Daru::DataFrame.from_csv "spec/data/logistic.csv"
      @data_set.vectors = Daru::Index.new([:x1,:x2,:y])
      @glm  = Statsample::GLM.compute @data_set, :y, :logistic, {constant: 1}
    end

    it "reports correct coefficients as an array" do
      expect_similar_array(@glm.coefficients(:array), [-0.312493754568903,
                                                       2.28671333346264,
                                                       0.675603176233325])
    end

    it "reports correct coefficients as a hash" do
      expect_similar_hash(@glm.coefficients(:hash), {:constant => 0.675603176233325,
                                                     :x1 => -0.312493754568903,
                                                     :x2 => 2.28671333346264})
    end

    it "reports correct coefficients as a Daru::Vector" do
      expect_similar_vector(@glm.coefficients, [-0.312493754568903,
                                                2.28671333346264, 0.675603176233325])
    end

    it "computes predictions on new data correctly" do
      new_data = Daru::DataFrame.new([[0.1, 0.2, 0.3], [-0.1, 0.0, 0.1]],
                                     order: [:x1, :x2])
      #predictions obtained in R with predict.glm with type='response':
      predictions = [0.6024496420392773, 0.6486486378079901, 0.6922216620285218]
      expect_similar_vector @glm.predict(new_data), predictions
    end
  end

  context "MLE algorithm" do
    before do
      @data_set = Daru::DataFrame.from_csv("spec/data/logistic_mle.csv")
      @data_set.vectors = Daru::Index.new([:a,:b,:c,:y])
      @glm      = Statsample::GLM.compute @data_set,:y, :logistic, {constant: 1, algorithm: :mle}
    end

    it "reports correct log-likelihood" do
      expect(@glm.log_likelihood).to be_within(0.001).of(-38.8669)
    end

    it "report the correct number of iterations" do
      expect(@glm.iterations).to eq(7)
    end

    it "reports correct regression coefficients as a Daru::Vector" do
      expect_similar_vector(@glm.coefficients, [0.3270, 0.8147, -0.4031,-5.3658], 0.001)
    end

    it "reports correct standard deviations as a Daru::Vector" do
      expect_similar_vector(@glm.standard_errors, [0.4390, 0.4270, 0.3819,1.9045], 0.001)
    end

    it "reports correct regression coefficients as an array" do
      expect_similar_array(@glm.coefficients(:array), [0.3270, 0.8147, -0.4031,-5.3658], 0.001)
    end

    it "reports correct standard deviations as an array" do
      expect_similar_array(@glm.standard_errors(:array), [0.4390, 0.4270, 0.3819,1.9045], 0.001)
    end

    it "reports correct regression coefficients as a hash" do
      expect_similar_hash(@glm.coefficients(:hash), {:a => 0.3270, :b => 0.8147, :c => -0.4031,
                                                     :constant => -5.3658}, 0.001)
    end

    it "reports correct standard deviations as a hash" do
      expect_similar_hash(@glm.standard_errors(:hash), {:a => 0.4390, :b => 0.4270, :c => 0.3819,
                                                       :constant => 1.9045}, 0.001)
    end

    it "computes predictions on new data correctly" do
      new_data = Daru::DataFrame.new([[-1.0, -150.0], [0.0, 150.0], [1.0, 150.0]],
                                     order: ['a', 'b', 'c'])
      #predictions obtained with in R predict.glm with type='response':
      predictions = [0.002247048350428831, 0.999341821607089287]
      expect_similar_vector @glm.predict(new_data), predictions
    end
  end
end
