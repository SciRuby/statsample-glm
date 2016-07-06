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

    context '2-way interaction' do
      context 'interaction of numerical with numerical' do
        context 'none reoccur' do
          let(:model) { described_class.new 'y ~ a:b', :logistic }
          subject { model.dataframe_for_regression }
          
          it { is_expected.to be_a Daru::DataFrame }
          its(:'vectors.to_a.sort') { is_expected.to eq(
            ['a:b', 'constant'].sort) }
          end
        
        context 'one reoccur' do
          let(:model) { described_class.new 'y ~ a+a:b', :logistic }
          subject { model.dataframe_for_regression }
          
          it { is_expected.to be_a Daru::DataFrame }
          its(:'vectors.to_a.sort') { is_expected.to eq(
            ['a', 'a:b', 'constant'].sort) }          
        end

        context 'both reoccur' do
          let(:model) { described_class.new 'y ~ a+a:b', :logistic }
          subject { model.dataframe_for_regression }
          
          it { is_expected.to be_a Daru::DataFrame }
          its(:'vectors.to_a.sort') { is_expected.to eq(
            ['a', 'a:b', 'b', 'constant'].sort) }          
        end        
      end
  
      context 'interaction of category with numerical' do
        context 'none reoccur' do
          let(:model) { described_class.new 'y ~ a:e', :logistic }
          subject { model.dataframe_for_regression }
          
          it { is_expected.to be_a Daru::DataFrame }
          its(:'vectors.to_a.sort') { is_expected.to eq(
            ['a:e_A', 'a:e_B', 'a:e_C', 'constant'].sort) }
        end

        context 'one reoccur' do
          context 'numeric occur' do
            let(:model) { described_class.new 'y ~ a+a:e', :logistic }
            subject { model.dataframe_for_regression }
            
            it { is_expected.to be_a Daru::DataFrame }
            its(:'vectors.to_a.sort') { is_expected.to eq(
              ['a', 'a:e_B', 'a:e_C', 'constant'].sort) }
          end

          context 'category occur' do
            let(:model) { described_class.new 'y ~ e+a:e', :logistic }
            subject { model.dataframe_for_regression }
            
            it { is_expected.to be_a Daru::DataFrame }
            its(:'vectors.to_a.sort') { is_expected.to eq(
              ['e_B', 'e_C', 'a:e_A', 'a:e_B', 'a:e_C', 'constant'].sort) }
          end  
        end        
        
        context 'both reoccur' do
          let(:model) { described_class.new 'y ~ a+a:e', :logistic }
          subject { model.dataframe_for_regression }
          
          it { is_expected.to be_a Daru::DataFrame }
          its(:'vectors.to_a.sort') { is_expected.to eq(
            ['e_B', 'e_C', 'a', 'a:e_B', 'a:e_C', 'constant'].sort) }
        end
      end
  
      context 'interaction of category with category' do
        context 'none reoccur' do
          let(:model) { described_class.new 'y ~ c:e', :logistic }
          subject { model.dataframe_for_regression }
          
          it { is_expected.to be_a Daru::DataFrame }
          its(:'vectors.to_a') { is_expected.to eq(
            ['e_B', 'e_C', 'c_yes:e_A', 'c_yes:e_B', 'c_yes:e_C', 'constant']
            .sort) }
        end

        context 'one reoccur' do
          let(:model) { described_class.new 'y ~ e+c:e', :logistic }
          subject { model.dataframe_for_regression }
          
          it { is_expected.to be_a Daru::DataFrame }
          its(:'vectors.to_a') { is_expected.to eq(
            ['e_B', 'e_C', 'c_yes:e_A', 'c_yes:e_B', 'c_yes:e_C', 'constant']
            .sort) }
        end

        context 'both reoccur' do
          let(:model) { described_class.new 'y ~ c:e', :logistic }
          subject { model.dataframe_for_regression }
          
          it { is_expected.to be_a Daru::DataFrame }
          its(:'vectors.to_a') { is_expected.to eq(
            ['c_yes', 'e_B', 'e_C', 'c_yes:e_B', 'c_yes:e_C', 'constant']
            .sort) }
        end        
      end
    end
    
    # TODO: Three way interaction
  end
end