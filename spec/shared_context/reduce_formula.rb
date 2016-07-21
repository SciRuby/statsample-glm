RSpec.shared_context "reduce formula" do |params|
  let(:input) { params.keys.first }
  let(:result) { params.values.first }

  let(:formula) { described_class.new 'y~a', df }
  subject { formula.reduce_formula input }

  it { is_expected.to be_a String }
  it { is_expected.to eq result }
end
