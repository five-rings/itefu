=begin
  ユニットテストを実行する
=end
module Itefu::UnitTest::Runner

  # テストケースを自動実行する
  # @param [Array<Class>] testcases 実行するテストケースの型 (UnitTest::TestCaseを継承したもの)
  # @note testcasesを指定しなかった場合、定義されているテストケースを探し実行する
  def self.run(output = $stderr, testcases = nil)
    testcases ||= Itefu::UnitTest::TestCase.subclasses
    testcases.each do |testcase|
      report(testcase.new.run, output) if testcase.auto_run?
    end
  rescue RGSSReset
  end

  # テストを実行した結果を出力する
  # @param [Itefu::UnitTest::Report] data 実行結果
  # param [IO] output 出力先
  def self.report(data, output)
    output.puts data.inspect
  end

end
