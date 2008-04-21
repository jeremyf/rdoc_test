require File.dirname(__FILE__) + '/../spec_helper.rb'
require 'yaml'
describe RdocTest::SourceScanner do
  YAML.load(File.new(File.join(File.dirname(__FILE__), '..', 'fixtures/sources.yml'))).each do |config|
    source = config[:source]
    if config[:has_tests]
      it "The following should have tests:\n#{source}" do
        with_source_file(source) do |filename|
          RdocTest::SourceScanner.new(filename).has_tests?.should == true
        end
      end
      it "The following should have tests that succeed:\n#{source}" do
        with_source_file(source) do |filename|
          scanner = RdocTest::SourceScanner.new(filename)
          with_run_test_wrapper(scanner, config[:test_should_succeed]) do
            scanner.run_tests!
          end
        end
      end
    else
      it "The following should NOT have tests:\n#{source}" do
        with_source_file(source) do |filename|
          RdocTest::SourceScanner.new(filename).has_tests?.should == false
        end
      end
    end
  end

  def with_run_test_wrapper(scanner, test_should_succeed)
    if test_should_succeed
      yield if block_given?
    else
      test_class_builder = Class.new(RdocTest::TestClassBuilder) do
        def test_class
          Class.new(Spec::ExampleGroup) do
            def raise_error(*args)
              Class.new(Spec::Matchers::RaiseError) do
                def matches?(*args)
                  !super
                end
              end.new(*args)
            end
          end
        end
      end.new(scanner)
      scanner.stubs(:test_builder).returns(test_class_builder)
      yield if block_given?
    end
    return
  end
  def with_source_file(source_code)
    # I'm including a time stamp because at some point, this process
    # will require the file, and if its already been required
    # then we'll have problems
    filename = File.join(File.dirname(__FILE__), "tmp.#{Time.now.to_f}.rb")
    begin
      File.open(filename, 'w+') {|f| f.puts source_code}
      yield(filename)
    ensure
      File.delete(filename) if File.exist?(filename)
    end
  end

  describe 'process_text' do
    before(:each) do
      @scanner = RdocTest::SourceScanner.new(__FILE__)
    end
    [
      [" >> User.new"           , :clear_setup_space  , ">"                 , true  ],
      [" # >> User.new"         , :add_setup_line     , "User.new"          , true  ],
      [" # >> User.new # => 4"  , :add_setup_line     , "User.new # => 4"   , true  ],
      [" # => '4 eggs'"         , :add_assert_line    , "'4 eggs'"          , true  ],
      [" => 4 "                 , :clear_setup_space  , "="                 , true  ],
      [" # RuntimeError: this"  , :add_exception_line , "RuntimeError"      , true  ],
      [" # === Now  "           , :clear_setup_space  , "# === Now"                 , true  ],
      [" "                      , :any_message        , nil                 , false ],
      [" # "                    , :any_message        , nil                 , false ],
    ].each do |line, checked_method_name, parameter, should_match|
      it "should #{'NOT ' unless should_match}send message #{checked_method_name.inspect} with #{parameter.inspect} for source code '#{line.inspect}'" do
        @scanner.class.each_process_text_method_name do |method_name|
          if method_name == checked_method_name && should_match
            @scanner.expects(method_name).with(parameter, 1).times(1)
          else
            @scanner.expects(method_name).times(0)
          end
        end
        @scanner.process_text(line, 1)
      end
    end
  end

end
