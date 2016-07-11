require 'spec_helper.rb'
require 'parser_checker.rb'

describe Statsample::GLM::Formula do
  context '#parse_formula' do
    context 'no interaction' do
      include_context 'parser checker', 'y~a+b' =>
        '1+a(-)+b(-)'
    end

    context '2-way interaction' do
      context 'none reoccur' do
        include_context 'parser checker', 'y~c+a:b' =>
          '1+c(-)+b(-)+a(-):b'
      end

      context 'first reoccur' do
        include_context 'parser checker', 'y~a+a:b' =>
          '1+a(-)+a:b(-)'
      end

      context 'second reoccur' do
        include_context 'parser checker', 'y~b+a:b' =>
          '1+b(-)+a(-):b'
      end 

      context 'both reoccur' do
        include_context 'parser checker', 'y~a+b+a:b' =>
          '1+a(-)+b(-)+a(-):b(-)'
      end
    end

    context 'complex cases' do
      include_context 'parser checker', 'y~a+a:b+b:d' =>
        '1+a(-)+a:b(-)+b:d(-)'
    end

    context 'constant management' do
      context 'add constant with 1' do
        include_context 'parser checker', 'y~1+a+b' =>
          '1+a(-)+b(-)'
      end

      context 'add constant by default' do
        include_context 'parser checker', 'y~a+b' =>
          '1+a(-)+b(-)'
      end

      context 'remove constant with 0' do
        include_context 'parser checker', 'y~a+b+0' =>
          'a+b(-)'
      end
    end
  end
end