require 'spec_helper.rb'
require 'shared_context/reduce_formula.rb'

describe Statsample::GLM::FormulaWrapper do
  context '#reduce_formula' do
    let(:df) { Daru::DataFrame.from_csv 'spec/data/df.csv' }

    before do
      df.to_category 'c', 'd', 'e'
    end

    context 'shortcut symbols' do
      context '*' do
        context 'two terms' do
          include_context 'reduce formula', 'y~a*b' => 'y~1+a+b+a:b'
        end

        context 'correct precedance' do
          context 'with :' do
            include_context 'reduce formula', 'y~a*b:c' =>
              'y~1+a+b:c+a:b:c'
          end

          context 'with +' do
            include_context 'reduce formula', 'y~a+b*c' =>
              'y~1+a+b+c+b:c'
          end
        end

        context 'more than two terms' do
          include_context 'reduce formula', 'y~a*b*c' =>
            'y~1+a+b+c+a:b+a:c+b:c+a:b:c'
        end
      end

      context '/' do
        context 'two terms' do
          include_context 'reduce formula', 'y~a/b' => 'y~1+a+a:b'
        end

        # TODO: Mismatch with Patsy
        xcontext 'more than two terms' do
          include_context 'reduce formula', 'y~a/b/c' =>
            'y~1+a+a:b+a:b:c'
        end

        context 'correct precedance' do
          context 'with :' do
            include_context 'reduce formula', 'y~a/b:c' =>
              'y~1+a+a:b:c'
          end

          context 'with +' do
            include_context 'reduce formula', 'y~a/b+c' =>
              'y~1+a+c+a:b'
          end
        end
      end

      context 'brackets' do
        context 'with + and :' do
          include_context 'reduce formula', 'y~(a+b):c' =>
            'y~1+a:c+b:c'
        end

        context 'with * and :' do
          include_context 'reduce formula', 'y~(a*b):c' =>
            'y~1+a:c+b:c+a:b:c'
        end

        xcontext 'with / and :' do
          include_context 'reduce formula', 'y~(a/b):c' =>
            'y~1+a:c+a:b:c'
        end

        # TODO: Mismatch with Patsy
        xcontext 'with * and /' do
          include_context 'reduce formula', 'y~(a*b)/c' =>
            'y~1+a+b+a:b+a:b:c'
        end
      end

      context 'corner cases' do
        context 'names of more than one character' do
          before do
            df['ax'] = df['a']
            df['bx'] = df['b']
          end
          include_context 'reduce formula', 'y~ax*bx:c' =>
            'y~1+ax+bx:c+ax:bx:c'
        end
      end

      context 'complex cases' do
        context 'example 1' do
          include_context 'reduce formula', 'y~(a+b)*(c+d)' =>
            'y~1+a+b+c+d+a:c+a:d+b:c+b:d'
        end
      end
    end
  end
end
