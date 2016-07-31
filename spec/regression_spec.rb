require 'spec_helper.rb'
require 'shared_context/formula_checker.rb'

describe Statsample::GLM::Regression do
  let(:df) { Daru::DataFrame.from_csv 'spec/data/df.csv' }
  before do
    df.to_category 'c', 'd', 'e'
  end

  context '#model' do
    context 'numerical' do
      let(:model) { described_class.new 'y ~ a+b+a:b', df, :logistic }
      let(:expected_hash) { {:a => 1.14462, :b => -0.04292, :'a:b' => -0.03011,
        :constant => 4.73822 } }
      subject { model.model }

      it { is_expected.to be_a Statsample::GLM::Logistic }
      it 'verifies the coefficients' do
        expect_similar_hash(subject.coefficients(:hash), expected_hash, 1e-5)
      end
    end
    
    context 'category' do
      let(:model) { described_class.new 'y ~ 0+c', df, :logistic }
      let(:expected_hash) { {c_no: -0.6931, c_yes: 1.3863 } }
      subject { model.model }

      it { is_expected.to be_a Statsample::GLM::Logistic }
      it 'verifies the coefficients' do
        expect_similar_hash(subject.coefficients(:hash), expected_hash, 1e-4)
      end      
    end
    
    context 'category and numeric' do
      let(:model) { described_class.new 'y ~ a+b:c', df, :logistic }
      let(:expected_hash) { {:constant => 16.8145, :a => -0.4315,
        :'c_no:b' => -0.2344, :'c_yes:b' => -0.2344} }
      subject { model.model }

      it { is_expected.to be_a Statsample::GLM::Logistic }
      it 'verifies the coefficients' do
        expect_similar_hash(subject.coefficients(:hash), expected_hash, 1e-2)
      end          
    end

    context 'other regression types' do
      # TODO: Right now it only verifies appropriate model gets generated
      # with appropriate coefficients but it doesn't verify the actual values
      # of coefficients.
      context 'normal' do
        let(:model) { described_class.new 'a ~ b:c', df, :normal, algorithm: :mle }
        subject { model.model }
        
        it { is_expected.to be_a Statsample::GLM::Normal }
        it { expect(subject.coefficients(:hash).keys).to eq(
          [:"c_no:b", :"c_yes:b", :constant]) }
      end

      context 'poisson' do
        let(:model) { described_class.new 'a ~ b:c', df, :poisson}
        subject { model.model }
        
        it { is_expected.to be_a Statsample::GLM::Poisson }
        it { expect(subject.coefficients(:hash).keys).to eq(
          [:"c_no:b", :"c_yes:b", :constant]) }        
      end

      context 'probit' do
        let(:model) { described_class.new 'a ~ b:c', df, :probit, algorithm: :mle}
        subject { model.model }
        
        it { is_expected.to be_a Statsample::GLM::Probit }
        it { expect(subject.coefficients(:hash).keys).to eq(
          [:"c_no:b", :"c_yes:b", :constant]) }
      end
    end
  end
  
  context '#predict' do
    context 'numerical' do
      let(:model) { described_class.new 'y ~ a+b+a:b', df, :logistic }
      let(:new_data) { df.head 3 }
      subject { model.predict new_data }

      it 'verifies the prediction' do
        expect_similar_vector(subject, [0.0930, 0.9936, 0.9931], 1e-4)
      end
    end 

    context 'category' do
      let(:model) { described_class.new 'y ~ 0+c', df, :logistic }
      let(:new_data) { df.head 3 }
      subject { model.predict new_data }

      it 'verifies the prediction' do
        expect_similar_vector(subject, [0.3333, 0.8, 0.3333], 1e-4)
      end  
    end
    
    context 'category and numeric' do
      let(:model) { described_class.new 'y ~ a+b:c', df, :logistic }
      let(:new_data) { df.head 3 }
      subject { model.predict new_data }

      it 'verifies the prediction' do
        expect_similar_vector(subject, [0.4183, 0.6961, 0.9993], 1e-4)
      end 
    end    
  end

  context '#df_for_regression' do
    context 'with intercept' do
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
              %w[e_A:a e_B:a e_C:a y]
          end
  
          context 'one reoccur' do
            context 'numeric occur' do
              include_context 'formula checker', 'y~a+a:e' =>
                %w[a e_B:a e_C:a y]
            end
  
            context 'category occur' do
              include_context 'formula checker', 'y~e+a:e' =>
                %w[e_B e_C e_A:a e_B:a e_C:a y]
            end  
          end        
          
          context 'both reoccur' do
            include_context 'formula checker', 'y~a+e+a:e' =>
              %w[a e_B e_C e_B:a e_C:a y]
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
    end

    context 'without intercept' do
      context 'no interaction' do
        include_context "formula checker", 'y~0+a+e' => %w[a e_A e_B e_C y]
      end
  
      context '2-way interaction' do
        context 'interaction of numerical with numerical' do
          context 'none reoccur' do
            include_context 'formula checker', 'y~0+a:b' =>
              %w[a:b y]
            end
          
          context 'one reoccur' do
            include_context 'formula checker', 'y~0+a+a:b' =>
              %w[a a:b y]
          end
  
          context 'both reoccur' do
            include_context 'formula checker', 'y~0+a+b+a:b' =>
              %w[a a:b b y]
          end        
        end
    
        context 'interaction of category with numerical' do
          context 'none reoccur' do
            include_context 'formula checker', 'y~0+a:e' =>
              %w[e_A:a e_B:a e_C:a y]
          end
  
          context 'one reoccur' do
            context 'numeric occur' do
              include_context 'formula checker', 'y~0+a+a:e' =>
                %w[a e_B:a e_C:a y]
            end
  
            context 'category occur' do
              include_context 'formula checker', 'y~0+e+a:e' =>
                %w[e_A e_B e_C e_A:a e_B:a e_C:a y]
            end  
          end        
          
          context 'both reoccur' do
            include_context 'formula checker', 'y~0+a+e+a:e' =>
              %w[a e_A e_B e_C e_B:a e_C:a y]
          end
        end
    
        context 'interaction of category with category' do
          context 'none reoccur' do
            include_context 'formula checker', 'y~0+c:e' =>
              %w[c_no:e_A c_no:e_B c_no:e_C c_yes:e_A c_yes:e_B c_yes:e_C y]
          end
  
          context 'one reoccur' do
            include_context 'formula checker', 'y~0+e+c:e' =>
              %w[e_A e_B e_C c_yes:e_A c_yes:e_B c_yes:e_C y]
          end
  
          context 'both reoccur' do
            include_context 'formula checker', 'y~0+c+e+c:e' =>
              %w[c_yes c_no e_B e_C c_yes:e_B c_yes:e_C y]
          end        
        end
      end      
    end

    context 'shortcut symbols' do
      context 'symbol *' do
        include_context 'formula checker', 'y~0+a*c' =>
          %w[a c_yes c_no c_yes:a y]
      end

      context 'symbol /' do
        include_context 'formula checker', 'y~a/c' =>
          %w[a c_yes:a y]
      end
    end

    context 'corner case' do
      context 'example 1' do
        include_context 'formula checker', 'y~d:a+d:e' =>
          %w[e_B e_C d_male:e_A d_male:e_B d_male:e_C d_female:a d_male:a y]
      end

      context 'example 2' do
        include_context 'formula checker', 'y~0+d:a+d:c' =>
          %w[d_female:c_no d_male:c_no d_female:c_yes d_male:c_yes d_female:a d_male:a y]
      end
    end

    context 'complex examples' do
      context 'random example 1' do
        include_context 'formula checker', 'y~a+e+c:d+e:d' =>
          %w[e_B e_C d_male c_yes:d_female c_yes:d_male e_B:d_male e_C:d_male a y]
      end
      
      context 'random example 2' do
        include_context 'formula checker', 'y~e+b+c+d:e+b:e+a:e+0' =>
          %w[e_A e_B e_C c_yes d_male:e_A d_male:e_B d_male:e_C b e_B:b e_C:b e_A:a e_B:a e_C:a y]
      end
    end    
    # TODO: Three way interaction
  end
end