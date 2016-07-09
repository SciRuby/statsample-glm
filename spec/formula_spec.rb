require 'spec_helper.rb'

describe Statsample::GLM::Formula do
  context '#initialize' do
    subject(:token) { described_class.new 'y ~ a+a:b+c:d' }
    
    it { is_expected.to eq Statsample::GLM::Formula }
    its(:size) { is_expected.to eq 3 }
    its(:to_a) { is_expected.to eq ['a', 'a:b', 'c:d']
      .map { |t| Statsample::GLM::Token.new t } }
  end

  context '#parse_formula' do
    context 'no interaction' do
      let(:formula) { described_class.new 'y ~ a+b' }
      subject { formula.parse_formula :string }
      
      it { is_expected.to eq '1+a(-)+b(-)' }
    end

    context '2-way interaction' do
      context 'none reoccur' do
        let(:formula) { described_class.new 'y ~ c+a:b' }
        subject { formula.parse_formula :string }
        
        it { is_expected.to eq '1+c(-)+b(-)+a(-):b' }
      end

      context 'first reoccur' do
        let(:formula) { described_class.new 'y ~ a+a:b' }
        subject { formula.parse_formula :string }
        
        it { is_expected.to eq '1+a(-)+a:b(-)' }
      end

      context 'second reoccur' do
        let(:formula) { described_class.new 'y ~ b+a:b' }
        subject { formula.parse_formula :string }
        
        it { is_expected.to eq '1+b(-)+a(-):b' }
      end 

      context 'both reoccur' do
        let(:formula) { described_class.new 'y ~ a+b+a:b' }
        subject { formula.parse_formula :string }
        
        it { is_expected.to eq '1+a(-)+b(-)+a(-):b(-)' }
      end
    end

    context 'complex cases' do
      let(:formula) { described_class.new 'y ~ a+a:b+b:d' }
      subject { formula.parse_formula :string }
      
      it { is_expected.to eq '1+a(-)+a:b(-)+b:d(-)' }
    end
  end
end