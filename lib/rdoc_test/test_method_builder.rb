module RdocTest
  class TestMethodBuilder
    def initialize(filename, lineno, setup_lines, expected_value)
      @filename = filename
      @lineno = lineno
      @setup_lines = setup_lines.dup
      @expected_value = expected_value.dup
    end

    def to_s
      build_assertion_text
      <<-end_src
      it "has inline test #{@filename}:#{@lineno} (i.e. #{@assertion_text})" do
        lambda do
          #{@setup_lines.join("\n")}
          #{@assertion_text}
        end.should_not raise_error(Exception)
      end
      end_src
    end
    
    protected
    def build_assertion_text
      @assertion_text = @setup_lines.pop
      @assertion_text += ".should == #{@expected_value}"
    end
  end
end
