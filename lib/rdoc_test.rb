$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module RdocTest
  def self.run(options)
    require 'rubygems'
    gem 'rspec'
    require 'spec'
    SourceScanner.new(options[:filename]).run_tests!
  end
end
require 'forwardable'
require 'rdoc_test/source_scanner'
require 'rdoc_test/test_class_builder'
require 'rdoc_test/test_method_builder'
