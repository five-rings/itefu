=begin
  Focusのテストコード
=end
class Itefu::Test::Focus < Itefu::UnitTest::TestCase

  class TestFocusable
    include Itefu::Focus::Focusable
    attr_reader :data

    def initialize
      @data = []
      super
    end
    
    def clear_data; data.clear; end
    def on_focused; data.push :focused; end
    def on_unfocused; data.push :unfocused; end
  end

  def test_focus
    instances = 3.times.map { TestFocusable.new }
    focus = Itefu::Focus::Controller.new.activate

    # push
    assert_same(instances[0], focus.push(instances[0]))
    assert(instances[0].focus)
    assert(instances[1].focus.!)
    assert(instances[2].focus.!)
    assert_equal([:focused], instances[0].data)
    assert_empty(instances[1].data)
    assert_empty(instances[2].data)
    instances.each(&:clear_data)    

    # push
    assert_same(instances[1], focus.push(instances[1]))
    assert(instances[0].focus.!)
    assert(instances[1].focus)
    assert(instances[2].focus.!)
    assert_equal([:unfocused], instances[0].data)
    assert_equal([:focused], instances[1].data)
    assert_empty(instances[2].data)
    instances.each(&:clear_data)    

    # switch
    assert_same(instances[2], focus.switch(instances[2]))
    assert(instances[0].focus.!)
    assert(instances[1].focus.!)
    assert(instances[2].focus)
    assert_empty(instances[0].data)
    assert_equal([:unfocused], instances[1].data)
    assert_equal([:focused], instances[2].data)
    instances.each(&:clear_data)

    # pop
    assert_same(instances[2], focus.pop)
    assert(instances[0].focus)
    assert(instances[1].focus.!)
    assert(instances[2].focus.!)
    assert_equal([:focused], instances[0].data)
    assert_empty(instances[1].data)
    assert_equal([:unfocused], instances[2].data)
    instances.each(&:clear_data)

    # 空になる状態でpop
    assert_same(instances[0], focus.pop)
    assert(instances[0].focus.!)
    assert(instances[1].focus.!)
    assert(instances[2].focus.!)
    assert_equal([:unfocused], instances[0].data)
    assert_empty(instances[1].data)
    assert_empty(instances[2].data)
    instances.each(&:clear_data)

    # 空の状態でpop
    assert_nil(focus.pop)
    assert(instances[0].focus.!)
    assert(instances[1].focus.!)
    assert(instances[2].focus.!)
    assert_empty(instances[0].data)
    assert_empty(instances[1].data)
    assert_empty(instances[2].data)
    instances.each(&:clear_data)

    instances.each {|instance| focus.push(instance) }
    instances.each(&:clear_data)
    assert_equal(instances, focus.instance_eval { @focus_graph })

    # rewind
    assert_same(instances[0], focus.rewind(instances[0]))
    assert(instances[0].focus)
    assert(instances[1].focus.!)
    assert(instances[2].focus.!)
    assert_equal([:focused], instances[0].data)
    assert_empty(instances[1].data)
    assert_equal([:unfocused], instances[2].data)
    instances.each(&:clear_data)

    # currentに対してrewind
    assert_same(instances[0], focus.rewind(instances[0]))
    assert(instances[0].focus)
    assert(instances[1].focus.!)
    assert(instances[2].focus.!)
    assert_empty(instances[0].data)
    assert_empty(instances[1].data)
    assert_empty(instances[2].data)
    instances.each(&:clear_data)

    # 存在しないものへrewind
    assert_nil(focus.rewind(instances[1]))
    assert(instances[0].focus.!)
    assert(instances[1].focus.!)
    assert(instances[2].focus.!)
    assert_equal([:unfocused], instances[0].data)
    assert_empty(instances[1].data)
    assert_empty(instances[2].data)
    instances.each(&:clear_data)

    focus.push(instances[0])
    focus.push(instances[1])
    instances.each(&:clear_data)
    assert_equal(instances[0..1], focus.instance_eval { @focus_graph })
    
    # reset
    assert_same(instances[2], focus.reset(instances[2]))
    assert(instances[0].focus.!)
    assert(instances[1].focus.!)
    assert(instances[2].focus)
    assert_empty(instances[0].data)
    assert_equal([:unfocused], instances[1].data)
    assert_equal([:focused], instances[2].data)
    assert_equal(instances[2..2], focus.instance_eval { @focus_graph })
    instances.each(&:clear_data)
    
    # operate
    instances[0].custom_operation = proc {|f| f.data << 1; nil }
    instances[0].operation_instructed = proc {|f| f.data << 2}
    instances[0].operate(nil)
    assert_equal([1], instances[0].data)
    instances.each(&:clear_data)
    instances[0].custom_operation = proc {|f| f.data << 1 }
    instances[0].operate(nil)
    assert_equal([1, 2], instances[0].data)
    instances.each(&:clear_data)
    
    # clear
    focus.clear
    assert(focus.empty?)
    assert_equal([], focus.instance_eval { @focus_graph })
    assert(instances[0].focus.!)
    assert(instances[1].focus.!)
    assert(instances[2].focus.!)
    assert_empty(instances[0].data)
    assert_empty(instances[1].data)
    assert_equal([:unfocused], instances[2].data)
    instances.each(&:clear_data)
  end

end
