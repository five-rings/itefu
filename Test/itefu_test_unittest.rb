=begin
  UnitTestのテストコード
=end
class Itefu::Test::UnitTest < Itefu::UnitTest::TestCase

  # --------------------------------------------------
  # Assertionのテスト

  def test_assert_raise
    assert_raises(StandardError) do
      raise
    end
    assert_raises(Itefu::UnitTest::Assertion::Failed) do
      assert_raises {}
    end
    
    assert_raises(Itefu::UnitTest::Assertion::Skipped) do
      assert_raises(StandardError) do 
        raise Itefu::UnitTest::Assertion::Skipped
      end
    end
  end
  
  def test_assert
    assert(true)
    assert_raises(Itefu::UnitTest::Assertion::Failed) do
      assert(false)
    end
  end
  
  def test_assert_block
    assert_block { true }
    assert_raises(Itefu::UnitTest::Assertion::Failed) do
      assert_block { false }
    end
  end
  
  def test_assert_empty
    assert_empty([])
    assert_raises(Itefu::UnitTest::Assertion::Failed) do
      assert_empty([1])
    end
  end

  def test_assert_not_empty
    assert_not_empty([1])
    assert_raises(Itefu::UnitTest::Assertion::Failed) do
      assert_not_empty([])
    end
  end
  
  def test_assert_equal
    assert_equal(10, 10.0)
    assert_raises(Itefu::UnitTest::Assertion::Failed) do
      assert_equal(10, 20)
    end
  end

  def test_assert_not_equal
    assert_not_equal(10, 20)
    assert_raises(Itefu::UnitTest::Assertion::Failed) do
      assert_not_equal(10, 10.0)
    end
  end
  
  def test_assert_in_delta
    assert_in_delta(10, 5, 5)
    assert_raises(Itefu::UnitTest::Assertion::Failed) do
      assert_in_delta(10, 5, 1)
    end
  end
  
  def test_assert_in_epsilon
    assert_in_epsilon(10, 5, 1)
    assert_raises(Itefu::UnitTest::Assertion::Failed) do
      assert_in_epsilon(10, 5, 0.1)
    end
  end
  
  def test_assert_includes
    assert_includes([1,2,3], 2)
    assert_raises(Itefu::UnitTest::Assertion::Failed) do
      assert_includes([1,2,3], 4)
    end
  end
  
  def test_assert_instance_of
    assert_instance_of(Fixnum, 10)
    assert_raises(Itefu::UnitTest::Assertion::Failed) do
      assert_instance_of(Integer, 10)
    end
  end
  
  def test_assert_kind_of
    assert_kind_of(Fixnum, 10)
    assert_raises(Itefu::UnitTest::Assertion::Failed) do
      assert_kind_of(Float, 10)
    end
  end
  
  def test_assert_match
    assert_match(/^abc$/, "abc")
    assert_raises(Itefu::UnitTest::Assertion::Failed) do
      assert_match(/d/, "abc")
    end
  end

  def test_assert_not_match
    assert_not_match(/d/, "abc")
    assert_raises(Itefu::UnitTest::Assertion::Failed) do
      assert_not_match(/^abc$/, "abc")
    end
  end
  
  def test_assert_nil
    assert_nil(nil)
    assert_raises(Itefu::UnitTest::Assertion::Failed) do
      assert_nil(10)
    end
  end
  
  def test_assert_not_nil
    assert_not_nil(10)
    assert_raises(Itefu::UnitTest::Assertion::Failed) do
      assert_not_nil(nil)
    end
  end
  
  def test_assert_operator
    assert_operator(10, :==, 10.0)
    assert_raises(Itefu::UnitTest::Assertion::Failed) do
      assert_operator(10, :!=, 10.0)
    end
  end
  
  def test_assert_respond_to
    assert_respond_to(10, :nil?)
    assert_raises(Itefu::UnitTest::Assertion::Failed) do
      assert_respond_to(10, :none?)
    end
  end
  
  def test_assert_same
    a = "a"
    assert_same(a, a)
    assert_raises(Itefu::UnitTest::Assertion::Failed) do
      assert_same(a, "a")
    end
  end
  
  def test_assert_not_same
    a = "a"
    assert_not_same(a, "a")
    assert_raises(Itefu::UnitTest::Assertion::Failed) do
      assert_not_same(a, a)
    end
  end
  
  def test_assert_send
    assert_send([10, :is_a?, Integer])
    assert_raises(Itefu::UnitTest::Assertion::Failed) do
      assert_send([10, :instance_of?, Integer])
    end
  end
  
  def test_assert_throws
    assert_throws(:symbol) do
      throw :symbol
    end
    assert_raises(Itefu::UnitTest::Assertion::Failed) do
      assert_throws(:symbol) {}
    end
  end


  # --------------------------------------------------
  # TestCaseとReportのテスト

  class Case < Itefu::UnitTest::TestCase
    def self.auto_run?; false; end

    def test_success
      assert(true)
    end

    def test_failure1
      assert(false)
    end

    def test_failure2
      assert_block { false }
      assert(true)
    end

    def test_failure3
      assert(true)
      assert_raises(StandardError) { }
      assert(true)
    end

    def test_error1
      assert(true)
      assert()
    end
    
    def test_error2
      exp = nil * 10
      assert(exp)
    end
    
    def test_skipped
      assert(true)
      assert(true)
      raise Itefu::UnitTest::Assertion::Skipped
      assert(true)
    end
  end

  def test_testcase
    report = Case.new.run
    assert_equal("Itefu::Test::UnitTest::Case", report.testcase.class.name)

    assert_equal(1, report.successes.size)
    assert_equal(1, report.successes.inject(0) {|m,d| m + d[:count] })

    assert_equal(3, report.failures.size)
    assert_equal(4, report.failures.inject(0) {|m,d| m + d[:count] })

    assert_equal(2, report.errors.size)
    assert_equal(1, report.errors.inject(0) {|m,d| m + d[:count] })

    assert_equal(1, report.skips.size)
    assert_equal(2, report.skips.inject(0) {|m,d| m + d[:count] })
  end

end
