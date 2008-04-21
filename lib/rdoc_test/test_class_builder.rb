module RdocTest
  class TestClassBuilder
    extend Forwardable
    def_delegator :@source_scanner, :filename
    def initialize(source_scanner)
      @source_scanner = source_scanner
    end

    def clear_setup_space(text, lineno)
      @setup_lines = []
    end

    def add_setup_line(text, lineno)
      setup_lines << text
    end

    def add_assert_line(text, lineno)
      test_method_bodies << builder(filename, lineno, setup_lines, text)
    end
    alias_method :add_exception_line, :add_assert_line

    def perform_tests
      # You'll really want this file if you are going to run a test against it.
      require filename
      test_method_bodies.each_with_index do |text_method_body, index|
        test_class.class_eval(text_method_body.to_s, __FILE__, __LINE__)
      end
    end
    protected
    def test_class
      @test_class ||= Class.new(Spec::ExampleGroup)
    end
    def builder(filename, lineno, setup_lines, text)
      TestMethodBuilder.new(filename, lineno, setup_lines, text)
    end
    def setup_lines
      @setup_lines ||= []
    end

    def test_method_bodies
      @test_method_bodies ||=[]
    end
    
  end
end
