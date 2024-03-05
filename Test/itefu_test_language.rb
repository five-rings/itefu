=begin
  Languageのテストコード
=end
class Itefu::Test::Language < Itefu::UnitTest::TestCase

  class TestLanguage
    include Itefu::Language::Loader
    def load_message(id, filename, locale = nil)
      super(id, ".", filename, locale)
    end
    def reload_messages(locale = nil)
      super(".", locale)
    end
  end

  def startup
    @test_data = { test: "テスト" }
    @test_data_en = { test: "Test" }

    save_data(@test_data, "test.dat")
    Dir::mkdir("en_us") unless File.directory? "en_us"
    save_data(@test_data_en, "en_us/test.dat")
  end
  
  def shutdown
    File.delete("test.dat")
    File.delete("en_us/test.dat")
    Dir::rmdir("en_us") if File.directory?("en_us")
  end
  
  def test_load_language
    language = TestLanguage.new
    language.locale = Itefu::Language::Locale::JA_JP
    language.load_message(:test, "test.dat")

    assert_equal("テスト", language.message(:test, :test))
    assert_nil(language.message(:test, :nomean))
    assert_raises(Itefu::Exception::AssertionFailed) do
      language.message(:not_test, :test)
    end
    
    # 英語に切り替える
    language.reload_messages(Itefu::Language::Locale::EN_US)
    assert_equal("Test", language.message(:test, :test))

    # フランス語に切り替える
    language.reload_messages(Itefu::Language::Locale::FR_FR)
    # 定義されていないのでデフォルトが読まれる
    assert_equal("テスト", language.message(:test, :test))
  end
  
  def test_ref_counter
    language = TestLanguage.new
    language.locale = Itefu::Language::Locale::JA_JP

    message = language.load_message(:test, "test.dat")
    assert_equal(1, message.ref_count)

    language.load_message(:test, "test.dat")
    assert_equal(2, message.ref_count)

    language.release_message(:test)
    assert_equal(1, message.ref_count)
    assert_equal("テスト", language.message(:test, :test))

    language.release_message(:test)
    assert(language.loaded_message?(:test).!)
  end
  
end
