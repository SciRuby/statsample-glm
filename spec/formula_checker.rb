RSpec.shared_context "formula checker", a => b do
  let(:model) { described_class.new df, a, :logistic }
  subject { model.df_for_regression }
  
  it { is_expected.to be_a Daru::DataFrame }
  its(:'vectors.to_a.sort') { is_expected.to eq b.sort }  
end