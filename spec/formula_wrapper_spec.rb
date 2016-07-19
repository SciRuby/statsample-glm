require 'spec_helper.rb'
require 'preprocess_checker.rb'

describe Statsample::GLM::FormulaWrapper do
  context '#preprocess_formula' do
    context 'shortcut symbols' do
      context '*' do
        include_context 'preprocess checker', 'a*b' => 'a+b+a:b'
      end

      context '/' do
        include_context 'preprocess checker', 'a/b' => 'a+a:b'
      end
    end
  end
end