require 'rspec/its'
require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rspec'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'statsample-glm'

def expect_similar_vector(exp, obs, delta=1e-10,msg=nil)
  expect(exp.is_a? Daru::Vector).to be true
  expect(exp.size).to eq(obs.size)

  exp.to_a.each_with_index do |v,i|
    expect(v).to be_within(delta).of(obs[i])
  end
end

def expect_similar_hash(exp, obs, delta=1e-10,msg=nil)
  expect(exp.is_a? Hash).to be true
  expect(exp.size).to eq(obs.size)

  exp.each_key do |k|
    expect(exp[k]).to be_within(delta).of(obs[k])
  end
end

def expect_similar_array(exp, obs, delta=1e-10,msg=nil)
  expect(exp.is_a? Array).to be true
  expect(exp.size).to eq(obs.size)

  exp.each_with_index do |v,i|
    expect(v).to be_within(delta).of(obs[i])
  end
end

def expect_equal_vector(exp,obs,delta=1e-10,msg=nil)
  expect(exp.is_a? Daru::Vector).to be true
  expect(exp.size).to eq(obs.size)

  exp.size.times do |i|
    expect(exp[i]).to be_within(delta).of(obs[i])
  end
end

def expect_equal_matrix(exp,obs,delta=1e-10,msg=nil)
  expect(exp.row_size).to eq(obs.row_size)
  expect(exp.column_size).to eq(obs.column_size)

  exp.row_size.times do |i|
    exp.column_size.times do |j|
      expect(exp[i,j]).to be_within(delta).of(obs[i,j])    
    end
  end
end
