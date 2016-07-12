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
      include_context "formula checker", 'y~a+e' => %w[a e_B e_C y]
    end

    context '2-way interaction' do
      context 'interaction of numerical with numerical' do
        context 'none reoccur' do
          include_context 'formula checker', 'y~a:b' =>
            %w[a:b y]
          end
        
        context 'one reoccur' do
          include_context 'formula checker', 'y~a+a:b' =>
            %w[a a:b y]
        end

        context 'both reoccur' do
          include_context 'formula checker', 'y~a+b+a:b' =>
            %w[a a:b b y]
        end        
      end
  
      context 'interaction of category with numerical' do
        context 'none reoccur' do
          include_context 'formula checker', 'y~a:e' =>
            %w[a:e_A a:e_B a:e_C y]
        end

        context 'one reoccur' do
          context 'numeric occur' do
            include_context 'formula checker', 'y~a+a:e' =>
              %w[a a:e_B a:e_C y]
          end

          context 'category occur' do
            include_context 'formula checker', 'y~e+a:e' =>
              %w[e_B e_C a:e_A a:e_B a:e_C y]
          end  
        end        
        
        context 'both reoccur' do
          include_context 'formula checker', 'y~a+a:e' =>
            %w[e_B e_C a a:e_B a:e_C y]
        end
      end
  
      context 'interaction of category with category' do
        context 'none reoccur' do
          include_context 'formula checker', 'y~c:e' =>
            %w[e_B e_C c_yes:e_A c_yes:e_B c_yes:e_C y]
        end

        context 'one reoccur' do
          include_context 'formula checker', 'y~e+c:e' =>
            %w[e_B e_C c_yes:e_A c_yes:e_B c_yes:e_C y]
        end

        context 'both reoccur' do
          include_context 'formula checker', 'y~c+e+c:e' =>
            %w[c_yes e_B e_C c_yes:e_B c_yes:e_C y]
        end        
      end
    end

    context 'complex' do
      include_context 'formula checker', 'y~a+e+c:d+e:d' =>
        %w[e_B e_C d_male c_yes:d_female c_yes:d_male e_B:d_male e_C:d_male a y]
    end    
    # TODO: Three way interaction
  end
end