RSpec.shared_context 'reduce formula' do |params|
  let(:input) { params.keys.first }
  let(:result) { params.values.first }

  let(:formula) { described_class.new input, df }
  subject { formula.to_s }

  it { is_expected.to be_a String }
  it { is_expected.to eq result }
end
