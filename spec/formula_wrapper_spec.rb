require 'spec_helper.rb'
require 'preprocess_checker.rb'

describe Statsample::GLM::FormulaWrapper do
  context '#preprocess_formula' do
    context 'shortcut symbols' do
      context '*' do
        context 'two terms' do
          include_context 'preprocess checker', 'a*b' => 'a+b+a:b'
        end

        context 'correct precedance' do
          context 'with :' do
            include_context 'preprocess checker', 'a*b:c' =>
              'a+b:c+a:b:c'
          end

          context 'with +' do
            include_context 'preprocess checker', 'a+b*c' =>
              'a+b+c+b:c'
          end
        end

        context 'more than two terms' do
          include_context 'preprocess checker', 'a*b*c' =>
            'y ~ a+b+a:b+c+a:c+b:c+a:b:c'
        end
      end

      context '/' do
        context 'two terms' do
          include_context 'preprocess checker', 'a/b' => 'a+a:b'
        end

        context 'more than two terms' do
          include_context 'preprocess checker', 'a/b/c' =>
            'a+a:b+a:b:c'
        end

        context 'correct precedance' do
          context 'with :' do
            include_context 'preprocess checker', 'a/b:c' =>
              'a+a:b:c'
          end

          context 'with +' do
            include_context 'preprocess checker', 'a/b+c' =>
              'a+a:b+c'
          end
        end
      end

      context 'brackets' do
        context 'with + and :' do
          include_context 'preprocess checker', '(a+b):c' =>
            'a:c+b:c'
        end

        context 'with * and :' do
          include_context 'preprocess checker', '(a*b):c' =>
            'a:c+b:c+a:b:c'
        end

        context 'with / and :' do
          include_context 'preprocess checker', '(a/b):c' =>
            'a:c+a:b:c'
        end

        context 'with * and /' do
          include_context 'preprocess checker' '(a*b)/c' =>
            'a+b+a:b+a:b:c'
        end
      end
    end
  end
end