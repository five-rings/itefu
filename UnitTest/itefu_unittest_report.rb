=begin
  ユニットテストを実行した結果
=end
class Itefu::UnitTest::Report
  attr_reader :testcase
  attr_reader :successes, :failures, :errors, :skips
  
  def initialize(testcase)
    @testcase = testcase
    @successes = []
    @failures = []
    @errors = []
    @skips = []
  end

  # 成功した情報を追加する
  # @param [String] name テスト名
  # @param [Fixnum] count assertion数
  def success(name, count)
    @successes << {
      name: name,
      count: count,
    }
  end
  
  # 失敗した情報を追加する
  # @param [String] name テスト名
  # @param [Fixnum] count assertion数
  # @param [Exception] exception 例外情報
  def failure(name, count, exception)
    @failures << {
      name: name,
      count: count,
      exception: exception,
    }
  end
  
  # エラー情報を追加する
  # @param [String] name テスト名
  # @param [Fixnum] count assertion数
  # @param [Exception] exception 例外情報
  def error(name, count, exception)
    @errors << {
      name: name,
      count: count,
      exception: exception,
    }
  end
  
  # スキップした情報を追加する
  # @param [String] name テスト名
  # @param [Fixnum] count assertion数
  # @param [Exception] exception 例外情報
  def skip(name, count, exception)
    @skips << {
      name: name,
      count: count,
      exception: exception,
    }
  end

  # @return [String] テストの結果を整形して出力する
  def inspect
    texts = []
    total = @successes.size + @failures.size + @errors.size + @skips.size
    count = @successes.inject(0) {|m,d| m + d[:count] } +
            @failures.inject(0) {|m,d| m + d[:count] } +
            @errors.inject(0) {|m,d| m + d[:count] } + 
            @skips.inject(0) {|m,d| m + d[:count] }

    @failures.each.with_index do |d, i|
      texts << ""
      texts << " #{i+1}) Failure: #{d[:exception].message}"
      texts << Itefu::Utility::String.script_name(
        d[:exception].backtrace.find {|info|
          (/itefu_unittest_assertion/ === Itefu::Utility::String.script_name(info)).!
        }
      )
    end
    
    @errors.each.with_index do |d, i|
      texts << ""
      texts << " #{i+1}) Error: #{d[:exception].message}"
      texts << d[:exception].backtrace.map {|info|
        Itefu::Utility::String.script_name(info)
      }
    end
    
    @skips.each.with_index do |d,i |
      texts << ""
      texts << " #{i+1}) Skip: #{d[:exception].message}"
      texts << Itefu::Utility::String.script_name(d[:exception].backtrace.first)
    end

    texts << ""
    texts << "#{@testcase.class.name}: #{total} tests, #{count} assertions, #{@failures.size} failures, #{@errors.size} errors, #{@skips.size} skips"
    texts.join("\n")
  end

end
