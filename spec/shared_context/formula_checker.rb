RSpec.shared_context 'formula checker' do |params|
  let(:formula) { params.keys.first }
  let(:vectors) { params.values.first }

  let(:model) { described_class.new formula, df, :logistic }
  subject { model.df_for_regression }

  it { is_expected.to be_a Daru::DataFrame }
  its(:'vectors.to_a.sort') { is_expected.to eq vectors.sort }
end
