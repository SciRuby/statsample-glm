require 'spec_helper.rb'

describe Statsample::GLM::Token do
  context '#initialize' do
    context 'no interaction' do
      context 'full' do
        subject(:token) { described_class.new 'a' }
        
        it { is_expected.to be_a described_class }
        its(:to_s) { is_expected.to eq 'a' }
        its(:full) { is_expected.to eq true }
      end

      context 'not-full' do
        subject(:token) { described_class.new 'a', false }
        
        it { is_expected.to be_a described_class }
        its(:to_s) { is_expected.to eq 'a(-)' }
        its(:full) { is_expected.to eq false }
      end
    end

    context '2-way interaction' do
      subject(:token) { described_class.new 'a:b', [true, false] }
      
      it { is_expected.to be_a described_class }
      its(:to_s) { is_expected.to eq 'a:b(-)' }
      its(:full) { is_expected.to eq [true, false] }
    end
  end

  context '#to_df' do
    let(:df) { Daru::DataFrame.from_csv 'spec/data/df.csv' }
    before do
      df.to_category 'c', 'd', 'e'
      df['c'].categories = ['no', 'yes']
      df['d'].categories = ['female', 'male']
      df['e'].categories = ['A', 'B', 'C']
    end

    context 'no interaction' do
      
    end
  end
end