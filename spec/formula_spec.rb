require 'spec_helper.rb'

describe Statsample::GLM::Formula do
  context '#parse_formula' do
    context 'no interaction' do
      let(:formula) { described_class.new 'y ~ a+b' }
      subject { formula.parse_formula }
      
      it { is_expected.to be_a Array }
      its(:first) { is_expected.to eq Statsample::GLM::Token }
      its(:to_basic_formula) { is_expected.to eq 'y ~ 1+a(-)+b(-)' }
    end

    context '2-way interaction' do
      context 'none reoccur' do
        let(:formula) { described_class.new 'y ~ c+a:b' }
        subject { formula.parse_formula }
        
        it { is_expected.to be_a Array }
        its(:first) { is_expected.to eq Statsample::GLM::Token }
        its(:to_basic_formula) { is_expected.to eq 'y ~ 1+c(-)+b(-)+a(-):b' }
      end

      context 'first reoccur' do
        let(:formula) { described_class.new 'y ~ a+a:b' }
        subject { formula.parse_formula }
        
        it { is_expected.to be_a Array }
        its(:first) { is_expected.to eq Statsample::GLM::Token }
        its(:to_basic_formula) { is_expected.to eq 'y ~ 1+a(-)+a:b(-)' }
      end

      context 'second reoccur' do
        let(:formula) { described_class.new 'y ~ b+a:b' }
        subject { formula.parse_formula }
        
        it { is_expected.to be_a Array }
        its(:first) { is_expected.to eq Statsample::GLM::Token }
        its(:to_basic_formula) { is_expected.to eq 'y ~ 1+b(-)+a(-):b' }
      end 

      context 'both reoccur' do
        let(:formula) { described_class.new 'y ~ a+b+a:b' }
        subject { formula.parse_formula }
        
        it { is_expected.to be_a Array }
        its(:first) { is_expected.to eq Statsample::GLM::Token }
        its(:to_basic_formula) { is_expected.to eq 'y ~ 1+a(-)+b(-)+a(-):b(-)' }
      end
    end
  end
end