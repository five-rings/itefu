=begin
  ユニットテストの簡易テストケース
=end
# @note テストケースを実装する場合、このクラスを継承し、'test_'ではじまるメソッドを定義する
class Itefu::UnitTest::TestCase
  include Itefu::UnitTest::Assertion
  
  # デフォルトで全テストケースを自動的にテストするか
  @@auto_run = true
  
  # @param [Boolean] val 全てのテストケースをデフォルトで自動実行するか
  def self.default_auto_run=(val)
    @@auto_run = val
  end
  
  # @oaram [Boolean] val 特定の派生クラスのテストを自動実行するか
  def self.auto_run=(val)
    @auto_run = val
  end

  # @return [Boolean] 自動テストの実行対象か
  def self.auto_run?; @auto_run.nil? ? @@auto_run : @auto_run; end

  # --------------------------------------------------
  # 派生クラスで実装する

  # このテストケースを実行する前に呼ばれる
  # @note 必要に応じてオーバーライドする
  def startup; end

  # このテストケースの全てのテストを実行し終えた後に呼ばれる
  # @note 必要に応じてオーバーライドする
  def shutdown; end

  # テストを実行する前に毎回呼ばれる
  # @note 必要に応じてオーバーライドする
  def setup; end

  # テストを実行した後に毎回呼ばれる
  # @note 必要に応じてオーバーライドする
  def teardown; end

  # --------------------------------------------------
  # 内部実装

  # このクラスを継承しているクラスの型の配列
  @@subclasses = []

  # @return [Array<Class>] このクラスを 継承しているクラスの配列
  def self.subclasses
    @@subclasses
  end

  def self.inherited(subclass)
    # TestCaseを継承しているクラスを記録しておく
    @@subclasses << subclass
    # そのうち他のクラスに継承されているものは除外する
    # 最上位クラスのみを対象にする
    @@subclasses.delete(subclass.ancestors[1])
  end

  # このテストケースの全てのテストを実行する
  # @return [Itefu::UnitTest::Report] 実行結果
  def run
    @report = Itefu::UnitTest::Report.new(self)
    startup
    self.class.instance_methods.each do |name|
      if /^test_/ === name
        reset_assertion_count
        setup
        begin
          self.send(name)
          @report.success(name, assertion_count)
        rescue Itefu::UnitTest::Assertion::Failed => e
          @report.failure(name, assertion_count, e)
        rescue Itefu::UnitTest::Assertion::Skipped => e
          @report.skip(name, assertion_count, e)
        rescue Exception => e
          @report.error(name, assertion_count, e)
        end
        teardown
      end
    end
    shutdown
    @report
  end

end
