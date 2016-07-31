RSpec.shared_context 'parser checker' do |params|
  let(:input) { params.keys.first }
  let(:parse_result) { params.values.first }

  let(:formula) do
    described_class.new(
      input.split('+').map { |i| Statsample::GLM::Token.new i }
    )
  end
  subject { formula.canonical_to_s }

  it { is_expected.to eq parse_result }
end
