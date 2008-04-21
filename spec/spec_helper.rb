require 'rubygems'
begin
  require 'spec'
rescue LoadError
  gem 'rspec'
  require 'spec'
end
gem 'mocha'
Spec::Runner.configure do |config|
  config.mock_with :mocha
end

$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'rdoc_test'
