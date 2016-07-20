require 'spec_helper.rb'

describe Statsample::GLM::Token do
  context '#initialize' do
    context 'no interaction' do
      context 'full' do
        subject(:token) { described_class.new 'a' }
        
        it { is_expected.to be_a described_class }
        its(:to_s) { is_expected.to eq 'a' }
        its(:full) { is_expected.to eq [true] }
      end

      context 'not-full' do
        subject(:token) { described_class.new 'a', false }
        
        it { is_expected.to be_a described_class }
        its(:to_s) { is_expected.to eq 'a(-)' }
        its(:full) { is_expected.to eq [false] }
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
      df['d'].base_category = 'female'
    end

    context 'no interaction' do
      context 'numerical' do
        context 'full rank' do
          let(:token) { Statsample::GLM::Token.new 'a', [true] }
          subject { token.to_df df }
          
          it { is_expected.to be_a Daru::DataFrame }
          it { expect(subject['a']).to eq df['a'] }
        end
  
        context 'reduced rank' do
          let(:token) { Statsample::GLM::Token.new 'a', [false] }
          subject { token.to_df df }

          it { is_expected.to be_a Daru::DataFrame }
          it { expect(subject['a']).to eq df['a'] }          
        end
      end

      context 'category' do
        context 'full rank' do
          let(:token) { Statsample::GLM::Token.new 'e', [true] }
          subject { token.to_df df }
          it { is_expected.to be_a Daru::
          DataFrame }
          its(:shape) { is_expected.to eq [14, 3] }
          its(:'vectors.to_a') { is_expected.to eq %w(e_A e_B e_C) }
        end
  
        context 'reduced rank' do
          let(:token) { Statsample::GLM::Token.new 'e', [false] }
          subject { token.to_df df }

          it { is_expected.to be_a Daru::DataFrame }
          its(:shape) { is_expected.to eq [14, 2] }
          its(:'vectors.to_a') { is_expected.to eq %w(e_B e_C) }
        end
      end      
    end

    context '2-way interaction' do
      context 'numerical-numerical' do
        let(:token) { Statsample::GLM::Token.new 'a:b', [true, false] }
        subject { token.to_df df }

        it { is_expected.to be_a Daru::DataFrame }
        its(:shape) { is_expected.to eq [14, 1] }
        its(:'vectors.to_a') { is_expected.to eq ['a:b'] }
        it { expect(subject['a:b'].to_a).to eq (df['a']*df['b']).to_a }
      end
      
      context 'category-category' do
        context 'full-full' do
          let(:token) { Statsample::GLM::Token.new 'c:d', [true, true] }
          subject { token.to_df df }
          it { is_expected.to be_a Daru::DataFrame }
          its(:shape) { is_expected.to eq [14, 4] }
          its(:'vectors.to_a') { is_expected.to eq(
            ["c_no:d_female", "c_no:d_male", "c_yes:d_female", "c_yes:d_male"]
          ) }
        end

        context 'full-reduced' do
          let(:token) { Statsample::GLM::Token.new 'c:d', [true, false] }
          subject { token.to_df df }
          it { is_expected.to be_a Daru::DataFrame }
          its(:shape) { is_expected.to eq [14, 2] }
          its(:'vectors.to_a') { is_expected.to eq ['c_no:d_male', 'c_yes:d_male'] }
        end
  
        context 'reduced-full' do
          let(:token) { Statsample::GLM::Token.new 'c:d', [false, true] }
          subject { token.to_df df }
          it { is_expected.to be_a Daru::DataFrame }
          its(:shape) { is_expected.to eq [14, 2] }
          its(:'vectors.to_a') { is_expected.to eq ['c_yes:d_female', 'c_yes:d_male'] }
        end

        context 'reduced-reduced' do
          let(:token) { Statsample::GLM::Token.new 'c:d', [false, false] }
          subject { token.to_df df }
          it { is_expected.to be_a Daru::DataFrame }
          its(:shape) { is_expected.to eq [14, 1] }
          its(:'vectors.to_a') { is_expected.to eq ['c_yes:d_male'] }
        end
      end

      context 'numerical-category' do
        context 'full-full' do
          let(:token) { Statsample::GLM::Token.new 'a:c', [true, true] }
          subject { token.to_df df }
          it { is_expected.to be_a Daru::DataFrame }
          its(:shape) { is_expected.to eq [14, 2] }
          its(:'vectors.to_a') { is_expected.to eq ['a:c_no', 'a:c_yes'] }
          it { expect(subject['a:c_no'].to_a).to eq(
            [6, 0, 6, 4, 0, 11, 8, 0, 0, 11, 0, 8, 2, 3]) }
          it { expect(subject['a:c_yes'].to_a).to eq(
            [0, 18, 0, 0, 5, 0, 0, 21, 2, 0, 1, 0, 0, 0]) }
        end

        context 'reduced-reduced' do
          let(:token) { Statsample::GLM::Token.new 'a:c', [false, false] }
          subject { token.to_df df }
          it { is_expected.to be_a Daru::DataFrame }
          its(:shape) { is_expected.to eq [14, 1] }
          its(:'vectors.to_a') { is_expected.to eq ['a:c_yes'] }
          it { expect(subject['a:c_yes'].to_a).to eq(
            [0, 18, 0, 0, 5, 0, 0, 21, 2, 0, 1, 0, 0, 0]) }
        end
      end

      context 'category-numerical' do
        context 'full-full' do
          let(:token) { Statsample::GLM::Token.new 'c:a', [true, true] }
          subject { token.to_df df }
          it { is_expected.to be_a Daru::DataFrame }
          its(:shape) { is_expected.to eq [14, 2] }
          its(:'vectors.to_a') { is_expected.to eq ['c_no:a', 'c_yes:a'] }
          it { expect(subject['c_no:a'].to_a).to eq(
            [6, 0, 6, 4, 0, 11, 8, 0, 0, 11, 0, 8, 2, 3]) }
          it { expect(subject['c_yes:a'].to_a).to eq(
            [0, 18, 0, 0, 5, 0, 0, 21, 2, 0, 1, 0, 0, 0]) }
        end

        context 'reduced-reduced' do
          let(:token) { Statsample::GLM::Token.new 'c:a', [false, false] }
          subject { token.to_df df }
          it { is_expected.to be_a Daru::DataFrame }
          its(:shape) { is_expected.to eq [14, 1] }
          its(:'vectors.to_a') { is_expected.to eq ['c_yes:a'] }
          it { expect(subject['c_yes:a'].to_a).to eq(
            [0, 18, 0, 0, 5, 0, 0, 21, 2, 0, 1, 0, 0, 0]) }
        end
      end      
    end
  end
end