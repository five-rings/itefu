=begin
  Configのテストコード
=end
class Itefu::Test::Config < Itefu::UnitTest::TestCase

  class TestConfig
    include Itefu::Config
    attr_reader :data

    def initialize
      @data = Struct.new(:field1, :field2).new
    end    
  end
  TEST_DATA = "test.rb"
  CONVERTED_TEST_DATA = TEST_DATA + Itefu::Config::DEFAULT_CONVERTED_EXTENSION

  def startup
    clear_test_files
  end
  
  def shutdown
    clear_test_files
  end
  
  def clear_test_files
    File.delete(TEST_DATA) if File.exists?(TEST_DATA)
    File.delete(CONVERTED_TEST_DATA) if File.exists?(CONVERTED_TEST_DATA)
  end

  def test_load_raw_config
    script = <<-EOS
      config.data.field1 = 123
      config.data.field2 = "something special"
    EOS
    File.open(TEST_DATA, "w") {|f|
      f.write script
    }

    config = TestConfig.new.load(TEST_DATA)
    assert_equal(123, config.data.field1)
    assert_equal("something special", config.data.field2)
  end
  
  def test_load_converted_file
    script = <<-EOS
      config.data.field1 = 456
      config.data.field2 = "something great"
    EOS
    save_data(script, CONVERTED_TEST_DATA)

    # 変換後のデータがあっても生データが優先される
    config = TestConfig.new.load(TEST_DATA)
    assert_equal(123, config.data.field1)
    assert_equal("something special", config.data.field2)

    File.delete(TEST_DATA) if File.exists?(TEST_DATA)

    # 生データが削除されれば変換後のデータが読まれる
    config.reload
    assert_equal(456, config.data.field1)
    assert_equal("something great", config.data.field2)
  end
  
  def test_load_invalid_data
    script = <<-EOS
      config.data = 123
    EOS
    File.open(TEST_DATA, "w") {|f|
      f.write script
    }

    assert_raises(NoMethodError) do
      TestConfig.new.load(TEST_DATA)
    end
  end
  
end
