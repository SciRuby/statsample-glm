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
      include_context "formula checker", 'y~a:e' => %w[a e_B e_C].sort
    end

    context '2-way interaction' do
      context 'interaction of numerical with numerical' do
        context 'none reoccur' do
          include_context 'formula checker', 'y~a:b' =>
            %w[a:b]
          end
        
        context 'one reoccur' do
          include_context 'formula checker', 'y~a+a:b' =>
            %w[a a:b]
        end

        context 'both reoccur' do
          include_context 'formula checker', 'y~a+b+a:b' =>
            %w[a a:b b]
        end        
      end
  
      context 'interaction of category with numerical' do
        context 'none reoccur' do
          include_context 'formula checker', 'y~a:e' =>
            %w[a:e_A a:e_B a:e_C]
        end

        context 'one reoccur' do
          context 'numeric occur' do
            include_context 'formula checker', 'y~a+a:e' =>
              %w[a a:e_B a:e_C]
          end

          context 'category occur' do
            include_context 'formula checker', 'y~e+a:e' =>
              %w[e_B e_C a:e_A a:e_B a:e_C]
          end  
        end        
        
        context 'both reoccur' do
          include_context 'formula checker', 'y~a+a:e' =>
            %w[e_B e_C a a:e_B a:e_C]
        end
      end
  
      context 'interaction of category with category' do
        context 'none reoccur' do
          include_context 'formula checker', 'y~c:e' =>
            %w[e_B e_C c_yes:e_A c_yes:e_B c_yes:e_C]
        end

        context 'one reoccur' do
          include_context 'formula checker', 'y~e+c:e' =>
            %w[e_B e_C c_yes:e_A c_yes:e_B c_yes:e_C]
        end

        context 'both reoccur' do
          include_context 'formula checker', 'y~c+e+c:e' =>
            %w[c_yes e_B e_C c_yes:e_B c_yes:e_C]
        end        
      end
    end

    context 'complex' do
      include_context 'formula checker', 'y~a+e+c:d+e:d' =>
        %w[e_B e_C d_male c_yes:d_female c_yes:d_male e_B:d_male e_C:d_male a]
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