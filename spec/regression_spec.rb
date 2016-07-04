require 'spec_helper.rb'

describe Statsample::GLM::Regression do
  let(:df) { Daru::DataFrame.from_csv 'spec/data/df.csv' }
  before do
    df.to_category 'c', 'd', 'e'
    df['c'].categories = ['yes', 'no']
    df['e'].categories = ['A', 'B', 'C']
  end

  context 'fit_model' do
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
end