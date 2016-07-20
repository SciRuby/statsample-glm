require 'spec_helper.rb'
require 'shared_context/parser_checker.rb'

describe Statsample::GLM::Formula do
  context '#parse_formula' do
    context 'no interaction' do
      include_context 'parser checker', '1+a+b' =>
        '1+a(-)+b(-)'
    end

    context '2-way interaction' do
      context 'none reoccur' do
        include_context 'parser checker', '1+c+a:b' =>
          '1+c(-)+b(-)+a(-):b'
      end

      context 'first reoccur' do
        include_context 'parser checker', '1+a+a:b' =>
          '1+a(-)+a:b(-)'
      end

      context 'second reoccur' do
        include_context 'parser checker', '1+b+a:b' =>
          '1+b(-)+a(-):b'
      end 

      context 'both reoccur' do
        include_context 'parser checker', '1+a+b+a:b' =>
          '1+a(-)+b(-)+a(-):b(-)'
      end
    end

    context 'complex cases' do
      include_context 'parser checker', '1+a+a:b+b:d' =>
        '1+a(-)+a:b(-)+b:d(-)'
    end
  end
end