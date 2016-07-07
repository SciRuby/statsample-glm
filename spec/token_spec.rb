describe Statsample::GLM::Token do
  context '#initialize' do
    context 'no interaction' do
      context 'full' do
        subject(:token) { described_class.new 'a' }
        
        it { is_expected.to eq described_class }
        its(:value) { is_expected.to eq 'a' }
        its(:full) { is_expected.to eq true }
      end

      context 'not-full' do
        subject(:token) { described_class.new 'a', false }
        
        it { is_expected.to eq described_class }
        its(:value) { is_expected.to eq 'a(-)' }
        its(:full) { is_expected.to eq false }
      end
    end

    context '2-way interaction' do
      subject(:token) { described_class.new 'a:b', [true, false] }
      
      it { is_expected.to eq described_class }
      its(:value) { is_expected.to eq 'a:b(-)' }
      its(:full) { is_expected.to eq [true, false] }
    end
  end
end