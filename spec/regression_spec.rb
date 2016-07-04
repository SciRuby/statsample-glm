require 'spec_helper.rb'

describe Statsample::GLM::Regression do
  let(:df) { Daru::DataFrame.from_csv 'spec/data/df.csv' }
  before do
    df.to_category 'c', 'd', 'e'
    df['c'].categories = ['yes', 'no']
    df['e'].categories = ['A', 'B', 'C']
  end

  context '#fit_model' do
    context 'no interaction' do
      let(:model) { described_class.new 'y ~ a+e', :logistic }
      subject { model.fit_model }
      
      # TODO: Verify the result in a better way
      it { is_expected.to eq Statsample::GLM::Logistic }
      its(:coefficients, :hash) { is_expected.to eq({
        :a=>-0.010812201208660738,
        :e_B=>-0.3048323141638691,
        :e_C=>0.7003828317120407,
        :constant=>0.140561459002858
      }) }
    end
  end

  context '#dataframe_for_regression' do
    context 'no interaction' do
      let(:model) { described_class.new 'y ~ a+e', :logistic }
      subject { model.dataframe_for_regression }
      
      it { is_expected.to be_a Daru::DataFrame }
      its(:'vectors.to_a') { is_expected.to eq(
        ['a', 'e_B', 'e_C']) }
    end

    context 'interaction of numerical with numerical' do
      let(:model) { described_class.new 'y ~ a+a:b', :logistic }
      subject { model.dataframe_for_regression }
      
      it { is_expected.to be_a Daru::DataFrame }
      its(:'vectors.to_a') { is_expected.to eq(
        ['a', 'a:b']) }      
    end

    context 'interaction of category with numerical' do
      let(:model) { described_class.new 'y ~ a+a:e', :logistic }
      subject { model.dataframe_for_regression }
      
      it { is_expected.to be_a Daru::DataFrame }
      its(:'vectors.to_a') { is_expected.to eq(
        ['a', 'a:e_B', 'a:e_C']) }      
    end

    # context 'interaction of category with category' do
    #   let(:model) { described_class.new 'y ~ a+c:e', :logistic }
    #   subject { model.dataframe_for_regression }
      
    #   it { is_expected.to be_a Daru::DataFrame }
    #   its(:'vectors.to_a') { is_expected.to eq(
    #     ['a', 'c_no:e_B', 'c_yes:e_B', 'c_no:e_C', 'c_yes:e_C']) }      
    # end

    # context 'interaction with variable repeated' do
    #   let(:model) { described_class.new 'y ~ c+c:e', :logistic }
    #   subject { model.dataframe_for_regression }
      
    #   it { is_expected.to be_a Daru::DataFrame }
    #   its(:'vectors.to_a') { is_expected.to eq }      
    # end
    
    # context 'interaction with both variables repeated' do
    #   let(:model) { described_class.new 'y ~ b+e+b:e', :logistic }
    #   subject { model.dataframe_for_regression }
      
    #   it { is_expected.to be_a Daru::DataFrame }
    #   its(:'vectors.to_a') { is_expected.to eq } 
    # end
    
    # TODO: Identify more corner cases
  end
end