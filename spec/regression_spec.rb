require 'spec_helper.rb'
require 'formula_checker.rb'

describe Statsample::GLM::Regression do
  let(:df) { Daru::DataFrame.from_csv 'spec/data/df.csv' }
  before do
    df.to_category 'c', 'd', 'e'
    df['c'].categories = ['no', 'yes']
    df['d'].categories = ['female', 'male']
    df['e'].categories = ['A', 'B', 'C']
  end

  # context '#fit_model' do
  #   let(:model) { described_class.new 'y ~ a + e + c:d + e:d', :logistic }
  #   subject { model.fit_model }
    
  #   # TODO: Write this spec
  #   it { is_expected.to eq Statsample::GLM::Logistic }
  #   its(:coefficients, :hash) { is_expected.to eq({
  #     contant: ,
  #     e_B: ,
  #     e_C: ,
  #     d_male: ,
  #     'c_yes:d_female': ,
  #     'c_yes:d_male': ,
  #     'e_B:d_male': ,
  #     'e_C:d_male': ,
  #     'a': 
  #   }) }
  # end

  context '#df_for_regression' do
    context 'no interaction' do
      # let(:model) { described_class.new df, 'y ~ a+e', :logistic }
      # subject { model.df_for_regression }
      
      # it { is_expected.to be_a Daru::DataFrame }
      # its(:'vectors.to_a.sort') { is_expected.to eq(
      #   ['a', 'e_B', 'e_C'].sort) }
      include_context "formula checker", 'y~a:e' => %w[a e_B e_C].sort
    end

    context '2-way interaction' do
      context 'interaction of numerical with numerical' do
        context 'none reoccur' do
          let(:model) { described_class.new df, 'y ~ a:b', :logistic }
          subject { model.df_for_regression }
          
          it { is_expected.to be_a Daru::DataFrame }
          its(:'vectors.to_a.sort') { is_expected.to eq(
            ['a:b'].sort) }
          end
        
        context 'one reoccur' do
          let(:model) { described_class.new df, 'y ~ a+a:b', :logistic }
          subject { model.df_for_regression }
          
          it { is_expected.to be_a Daru::DataFrame }
          its(:'vectors.to_a.sort') { is_expected.to eq(
            ['a', 'a:b'].sort) }          
        end

        context 'both reoccur' do
          let(:model) { described_class.new df, 'y ~ a+b+a:b', :logistic }
          subject { model.df_for_regression }
          
          it { is_expected.to be_a Daru::DataFrame }
          its(:'vectors.to_a.sort') { is_expected.to eq(
            ['a', 'a:b', 'b'].sort) }          
        end        
      end
  
      context 'interaction of category with numerical' do
        context 'none reoccur' do
          let(:model) { described_class.new df, 'y ~ a:e', :logistic }
          subject { model.df_for_regression }
          
          it { is_expected.to be_a Daru::DataFrame }
          its(:'vectors.to_a.sort') { is_expected.to eq(
            ['a:e_A', 'a:e_B', 'a:e_C'].sort) }
        end

        context 'one reoccur' do
          context 'numeric occur' do
            let(:model) { described_class.new df, 'y ~ a+a:e', :logistic }
            subject { model.df_for_regression }
            
            it { is_expected.to be_a Daru::DataFrame }
            its(:'vectors.to_a.sort') { is_expected.to eq(
              ['a', 'a:e_B', 'a:e_C'].sort) }
          end

          context 'category occur' do
            let(:model) { described_class.new df, 'y ~ e+a:e', :logistic }
            subject { model.df_for_regression }
            
            it { is_expected.to be_a Daru::DataFrame }
            its(:'vectors.to_a.sort') { is_expected.to eq(
              ['e_B', 'e_C', 'a:e_A', 'a:e_B', 'a:e_C'].sort) }
          end  
        end        
        
        context 'both reoccur' do
          let(:model) { described_class.new df, 'y ~ a+a:e', :logistic }
          subject { model.df_for_regression }
          
          it { is_expected.to be_a Daru::DataFrame }
          its(:'vectors.to_a.sort') { is_expected.to eq(
            ['e_B', 'e_C', 'a', 'a:e_B', 'a:e_C'].sort) }
        end
      end
  
      context 'interaction of category with category' do
        context 'none reoccur' do
          let(:model) { described_class.new df, 'y ~ c:e', :logistic }
          subject { model.df_for_regression }
          
          it { is_expected.to be_a Daru::DataFrame }
          its(:'vectors.to_a.sort') { is_expected.to eq(
            ['e_B', 'e_C', 'c_yes:e_A', 'c_yes:e_B', 'c_yes:e_C']
            .sort) }
        end

        context 'one reoccur' do
          let(:model) { described_class.new df, 'y ~ e+c:e', :logistic }
          subject { model.df_for_regression }
          
          it { is_expected.to be_a Daru::DataFrame }
          its(:'vectors.to_a.sort') { is_expected.to eq(
            ['e_B', 'e_C', 'c_yes:e_A', 'c_yes:e_B', 'c_yes:e_C']
            .sort) }
        end

        context 'both reoccur' do
          let(:model) { described_class.new df, 'y ~ c+e+c:e', :logistic }
          subject { model.df_for_regression }
          
          it { is_expected.to be_a Daru::DataFrame }
          its(:'vectors.to_a.sort') { is_expected.to eq(
            ['c_yes', 'e_B', 'e_C', 'c_yes:e_B', 'c_yes:e_C']
            .sort) }
        end        
      end
    end

    context 'complex' do
      let(:model) { described_class.new df, 'y ~ a + e + c:d + e:d', :logistic }
      subject { model.df_for_regression }
      
      it { is_expected.to be_a Daru::DataFrame }
      its(:'vectors.to_a.sort') { is_expected.to eq(
        ['contant', 'e_B', 'e_C', 'd_male', 'c_yes:d_female', 'c_yes:d_male',
        'e_B:d_male', 'e_C:d_male', 'a'].sort
      ) }
    end    
    # TODO: Three way interaction
  end

  # context '#df_from_token' do
  #   let(:df) { Daru::DataFrame.from_csv 'spec/data/df.csv' }
  #   before do
  #     df.to_category 'c', 'd', 'e'
  #     df['c'].categories = ['no', 'yes']
  #     df['d'].categories = ['female', 'male']
  #     df['e'].categories = ['A', 'B', 'C']
  #   end

  #   context 'no interaction' do
  #     context 'numeric' do
  #       context 'full' do
  #         let(:token) { Token.new('a', true).df_from_token }
  #         subject { described_class.df_from_token df, token }
    
  #         it { is_expected.to eq Daru::DataFrame }
  #         its(:shape) { is_expected.to eq [14, 1] }
  #         its(:'vectors.to_a') { is_expected.to eq ['a'] }
  #         it { expect(subject['a']).to eq df['a'] }
  #       end

  #       context 'not-full' do
  #         let(:token) { Token.new('a', false).df_from_token }
  #         subject { described_class.df_from_token df, token }
    
  #         it { is_expected.to eq Daru::DataFrame }
  #         its(:shape) { is_expected.to eq [14, 1] }
  #         its(:'vectors.to_a') { is_expected.to eq ['a'] }
  #         it { expect(subject['a']).to eq df['a'] }          
  #       end
  #     end

  #     context 'category' do
  #       context 'full' do
  #         let(:token) { Token.new('e', true).df_from_token }
  #         subject { described_class.df_from_token df, token }
    
  #         it { is_expected.to eq Daru::DataFrame }
  #         its(:shape) { is_expected.to eq [14, 3] }
  #         its(:'vectors.to_a') { is_expected.to eq ['a'] }
  #         it { is_expected.to eq df['e'].contrast_code true }
  #       end

  #       context 'not-full' do
  #         subject { Token.new('e', false).df_from_token }
  #         subject { described_class.df_from_token df, token }
          
    
  #         it { is_expected.to eq Daru::DataFrame }
  #         its(:shape) { is_expected.to eq [14, 2] }
  #         its(:'vectors.to_a') { is_expected.to eq ['e_A', 'e_B', 'e_C'] }
  #         it { is_expected.to eq df['e'].contrast_code false }
  #       end
  #     end
  #   end

  #   context '2-way interaction' do
  #     context 'numeric-numeric' do
        
  #     end

  #     context 'category-numeric' do
        
  #     end

  #     context 'numeric-category' do
        
  #     end

  #     context 'category-category' do
        
  #     end
  #   end
  # end
end