=begin
  Systemのテストコード
=end
class Itefu::Test::System < Itefu::UnitTest::TestCase

  class DummySystem1 < Itefu::System::Base
    attr_reader :value
    def on_update
      @value = :updated
    end
    def on_finalize
      @value = :finalized
    end
  end

  class DummySystem2 < DummySystem1
    def on_initialize(value); @value = value; end
  end

  def test_manager
    manager = Itefu::System::Manager.new(self)
    s1 = manager.register(DummySystem1)
    s2 = manager.register(DummySystem2, 10)

    assert_equal(2, manager.systems.size)    
    assert_nil(s1.value)
    assert_equal(10, s2.value)
    assert_same(self, s1.application)
    assert_same(self, s2.application)
    
    manager.update
    assert_equal(:updated, s1.value)
    assert_equal(:updated, s2.value)

    manager.shutdown
    assert_equal(0, manager.systems.size)
    assert_equal(:finalized, s1.value)
    assert_equal(:finalized, s2.value)
  end
  
end
