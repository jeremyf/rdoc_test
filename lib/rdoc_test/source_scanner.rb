require 'forwardable'
module RdocTest
  class SourceScanner
    TEST_LINE = '^ *# *>> ?(.*)'
    ASSERT_LINE =  '^ *# *=> ?(.*)'
    CLEAR_NAME_SPACE_LINE = '^ *([^\#\ ]|#.*[^\ ]+)'
    EXCEPTION_LINES = '^ *# *([A-Z]\w*):.*\s *# *from \('
    EXCEPTION_LINE = '^ *# *([A-Z]\w*):.*'
    attr_reader :filename
    # >> RdocTest::SourceScanner.new($0).has_tests?
    # => true
    def initialize(filename)
      raise "You must specify a filename" unless filename
      raise "#{filename} does not exist" unless File.exist?(filename)
      @filename = filename
    end

    def run_tests!
      return true unless has_tests?
      collect_tests
      perform_tests
      return true
    end

    def has_tests?
      return true if /#{TEST_LINE}\s(#{EXCEPTION_LINES}|#{ASSERT_LINE})/.match(source_code)
      return false
    end

    class << self
      def each_process_text_method_name(&block)
        [[:add_setup_line, TEST_LINE, 1], [:add_assert_line, ASSERT_LINE, 1], [:add_exception_line, EXCEPTION_LINE, 1], [:clear_setup_space, CLEAR_NAME_SPACE_LINE, 1]].each do |method_name, regexp_text, match_data_index|
          if block_given?
            case block.arity
            when 3 then block.call(method_name, regexp_text, rematch_data_index)
            else block.call(method_name)
            end
          end
        end
      end
    end


    def process_text(line, lineno)
      self.class.each_process_text_method_name.each do |method_name, regexp_text, match_data_index|
        if matched_data = line.match(/#{regexp_text}/) #matched_data[match_data_index]
          send(method_name, matched_data[match_data_index].strip, lineno)
          break
        end
      end
    end

    protected
    def collect_tests
      source_code.split("\n").each_with_index do |line, lineno|
        process_text(line, lineno + 1)
      end
    end

    def source_code
      @source_code ||= File.read(filename)
    end


    extend Forwardable
    def_delegators :test_builder,  :perform_tests, :test_class
    each_process_text_method_name do |method_name|
      def_delegator :test_builder, method_name
    end
    def test_builder
      @test_builder ||= TestClassBuilder.new(self)
    end
  end
end

if __FILE__ == $0
  require 'rubygems'
  gem 'rspec'
  require 'spec'
  require File.dirname(__FILE__) + '/test_class_builder'
  require File.dirname(__FILE__) + '/test_method_builder'

  RdocTest::SourceScanner.new(__FILE__).run_tests!
end
