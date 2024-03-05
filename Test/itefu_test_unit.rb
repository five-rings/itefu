=begin
  Unitのテストコード
=end
class Itefu::Test::Unit < Itefu::UnitTest::TestCase

  class TestUnitManager
    include Itefu::Unit::Manager
    attr_accessor :data
    def initialize
      @data = []
      super
    end
    def clear_data
      @data.clear
    end
  end
  
  class TestUnit < Itefu::Unit::Base
    attr_reader :name
    def unit_id; name.hash; end
    def detached?; @detached.!.!; end

    def on_initialize(name)
      @name = name
    end
    
    def on_update
      manager.data.push "update #{name}"
    end
    def on_draw
      manager.data.push "draw #{name}"
    end
    def on_finalize
      manager.data.push "finalize #{name}"
    end
    def on_attached
      manager.data.push "attach #{name}"
    end
    def on_detached
      @detached = true
    end
  end

  class TestUnit1 < TestUnit
    def default_priority; 100; end
    
    def on_test_signaled(value)
      manager.data.push "test #{name} #{value}"
    end
  end

  class TestUnit2 < TestUnit
    def default_priority; 10; end
  end
  
  class TestUnits < Itefu::Unit::Composite
    def default_priority; 1; end
  end

  def test_unit_registration
    manager = TestUnitManager.new

    assert_instance_of(TestUnit1, manager.add_unit(TestUnit1, "1"))
    assert_instance_of(TestUnit2, manager.add_unit(TestUnit2, "2"))
    assert_instance_of(TestUnit1, manager.add_unit(TestUnit1, "1-2"))
    assert_equal(3, manager.units.size)
    assert_equal(3, manager.instance_eval { @units.size })

    # updateのテスト
    manager.clear_data
    manager.update_units
    assert_equal("update 2", manager.data[0])
    assert_equal("update 1", manager.data[1])
    assert_equal("update 1-2", manager.data[2])

    # 挿入のテスト
    unit3 = manager.add_unit_with_priority(50, TestUnit1, "3")
    assert_instance_of(TestUnit1, unit3)
    assert_equal(4, manager.units.size)
    assert_equal(4, manager.instance_eval { @units.size })

    # 描画のテスト
    manager.clear_data
    manager.draw_units
    assert_equal("draw 2", manager.data[0])
    assert_equal("draw 3", manager.data[1])
    assert_equal("draw 1", manager.data[2])
    assert_equal("draw 1-2", manager.data[3])

    # シグナルのテスト
    unit3.signaled(:test) {|unit, value|
      unit.manager.data.push "test #{unit.name} {#{value}}"
    }
    manager.clear_data
    manager.send_signal(:test, 10)
    assert_equal("test 3 {10}", manager.data[0])
    assert_equal("test 3 10", manager.data[1])
    assert_equal("test 1 10", manager.data[2])
    assert_equal("test 1-2 10", manager.data[3])

    # 削除のテスト
    manager.clear_data
    assert_same(unit3, manager.remove_unit(unit3))
    assert_equal(3, manager.units.size)
    assert_equal(3, manager.instance_eval { @units.size })
    assert_equal("finalize 3", manager.data[0])

    # アタッチのテスト
    manager.clear_data
    assert_same(unit3, manager.attach_unit(unit3))
    assert_equal(4, manager.units.size)
    assert_equal(4, manager.instance_eval { @units.size })
    assert_equal("attach 3", manager.data[0])

    # デタッチのテスト
    assert(unit3.detached?.!)
    manager.clear_data
    assert_same(unit3, manager.detach_unit(unit3))
    assert_equal(3, manager.units.size)
    assert_equal(3, manager.instance_eval { @units.size })
    assert_nil(manager.data[0])
    assert(unit3.detached?)

    # 条件指定デタッチ
    assert_same(unit3, manager.attach_unit(unit3))
    manager.clear_data
    manager.detach_units_if {|u|
      unit3 === u
    }
    assert_equal(3, manager.units.size)
    assert_equal(3, manager.instance_eval { @units.size })
    assert(unit3.detached?)

    # 条件指定削除
    assert_same(unit3, manager.attach_unit(unit3))
    manager.clear_data
    manager.remove_units_if {|u|
      unit3 === u
    }
    assert_equal(3, manager.units.size)
    assert_equal(3, manager.instance_eval { @units.size })
    assert_equal("finalize 3", manager.data[0])

    # まとめてデタッチ
    unit4 = manager.add_unit_with_priority(50, TestUnit1, "4")
    assert_same(unit3, manager.attach_unit(unit3))
    assert_equal(5, manager.units.size)
    assert_equal(5, manager.instance_eval { @units.size })
    manager.clear_data
    manager.detach_units([unit3, unit4])
    assert_equal(3, manager.units.size)
    assert_equal(3, manager.instance_eval { @units.size })
    assert(unit3.detached?)
    assert(unit4.detached?)

    # まとめて削除
    assert_same(unit3, manager.attach_unit(unit3))
    assert_same(unit4, manager.attach_unit(unit4))
    assert_equal(5, manager.units.size)
    assert_equal(5, manager.instance_eval { @units.size })
    manager.clear_data
    manager.remove_units([unit3, unit4])
    assert_equal(3, manager.units.size)
    assert_equal(3, manager.instance_eval { @units.size })
    assert_equal("finalize 3", manager.data[0])
    assert_equal("finalize 4", manager.data[1])

    # 全削除のテスト
    manager.clear_data
    manager.clear_all_units
    assert_equal(0, manager.units.size)
    assert_equal(0, manager.instance_eval { @units.size })
    assert_equal("finalize 2", manager.data[0])
    assert_equal("finalize 1", manager.data[1])
    assert_equal("finalize 1-2", manager.data[2])
  end

  def test_composite_unit
    manager = TestUnitManager.new

    units = manager.add_unit(TestUnits)
    assert_instance_of(TestUnits, units)

    assert_instance_of(TestUnit1, units.add_unit(TestUnit1, "1"))
    assert_instance_of(TestUnit2, units.add_unit(TestUnit2, "2"))
    assert_instance_of(TestUnit1, units.add_unit(TestUnit1, "1-2"))

    # updateのテスト
    manager.clear_data
    manager.update_units
    assert_equal("update 2", manager.data[0])
    assert_equal("update 1", manager.data[1])
    assert_equal("update 1-2", manager.data[2])

    # 描画のテスト
    manager.clear_data
    manager.draw_units
    assert_equal("draw 2", manager.data[0])
    assert_equal("draw 1", manager.data[1])
    assert_equal("draw 1-2", manager.data[2])

    # デタッチのテスト
    manager.clear_data
    assert_same(units, manager.detach_unit(units))
    units.units.each do |unit|
      assert(unit.detached?)
    end

    # アタッチのテスト
    manager.clear_data
    assert_same(units, manager.attach_unit(units))
    assert_equal("attach 2", manager.data[0])
    assert_equal("attach 1", manager.data[1])
    assert_equal("attach 1-2", manager.data[2])

    # シグナルのテスト
    manager.clear_data
    manager.send_signal(:test, 10)
    assert_equal("test 1 10", manager.data[0])
    assert_equal("test 1-2 10", manager.data[1])

    # 全削除のテスト
    manager.clear_data
    manager.clear_all_units
    assert_equal("finalize 2", manager.data[0])
    assert_equal("finalize 1", manager.data[1])
    assert_equal("finalize 1-2", manager.data[2])
  end

end
