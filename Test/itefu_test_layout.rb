=begin
  Layoutのテストコード
=end
class Itefu::Test::Layout < Itefu::UnitTest::TestCase

  class TestBindingControl < Itefu::Layout::Control::Base
    attr_reader :data
    def clear_data; data.clear; end

    def initialize
      @data = []
      super(nil)
    end

    def binding_value_changed(name, old_value)
      @data.push name
    end
  end

  def test_binding_object
    control = TestBindingControl.new
    assert_equal([:width, :height, :margin, :padding, :visibility], control.data)
    control.data.clear

    # 値を値を割り当て
    control.width = 10
    assert_equal([:width], control.data)
    control.data.clear

    # 値をBindingObjectで上書き
    bobj = control.binding { 10 }
    control.width = bobj
    assert_equal([:width], control.data)
    control.data.clear
    
    # 同じBindingObjectを割り当て
    control.width = bobj
    assert_equal([], control.data)
    control.data.clear
    
    # 別のBindingObjectで上書き
    control.width = control.binding { 10 }
    assert_equal([:width], control.data)
    control.data.clear
    
    # BindingObjectを値で上書き
    control.width = 10
    assert_equal([:width], control.data)
    control.data.clear
    
    # 値に同じ値を上書き
    control.width = 10
    assert_equal([], control.data)
    control.data.clear

    # 違う値で上書き
    control.width = 20
    assert_equal([:width], control.data)
    control.data.clear

    # 不正なbindingの生成
    assert_raises(ArgumentError) do
      control.binding
    end

    # 別のコントロールにひもづいたBindingObjectを割り当て
    control2 = TestBindingControl.new
    assert_raises(Itefu::Exception::AssertionFailed) do
      control.width = control2.binding { 10 }
    end

    # 同じBndingObjectを複数の属性に割り当て
    bobj = control.binding { 10 }
    control.width = bobj
    assert_raises(Itefu::Exception::AssertionFailed) do
      control.height = bobj
    end
  end
  
  def test_observable_object
    observable = Itefu::Layout::ObservableObject.new(10)
    controls = 2.times.map { TestBindingControl.new }
    controls.each(&:clear_data)

    controls.each {|control| control.width = control.binding { observable } }
    controls.each {|control| assert_equal([:width], control.data) }
    assert_equal(2, observable.instance_eval { @observers.size })
    controls.each(&:clear_data)

    # 値を変更
    observable.value = 20
    assert_equal(20, observable.value)
    controls.each {|control| assert_equal([:width], control.data)}
    controls.each(&:clear_data)

    # 同じ値で上書き
    observable.value = 20
    assert_equal(20, observable.value)
    controls.each {|control| assert_equal([], control.data)}
    controls.each(&:clear_data)
    
    # 強制的に変更を通知
    observable.modify(20)
    assert_equal(20, observable.value)
    controls.each {|control| assert_equal([:width], control.data)}
    controls.each(&:clear_data)
    
    # 強制的に変更を通知
    observable.change(true) do |value|
      assert_equal(20, value)
    end
    controls.each {|control| assert_equal([:width], control.data)}
    controls.each(&:clear_data)

    # 変更されていれば通知
    observable.change do |value|
      # 何もしない
    end
    controls.each {|control| assert_equal([], control.data)}
    controls.each(&:clear_data)

    # 変更されていれば通知
    observable.change do |value|
      # 変更する
      observable.value = value + 1
    end
    controls.each {|control| assert_equal([:width], control.data)}
    controls.each(&:clear_data)
    
    # コントロールの削除
    controls[0].finalize
    observable.value = 0
    assert_equal([], controls[0].data)
    assert_equal([:width], controls[1].data)
    assert_equal(1, observable.instance_eval { @observers.size })
    controls.each(&:clear_data)
    
    # BindingObject側からObservableを変更
    controls[1].width = 10
    assert_equal([], controls[0].data)
    assert_equal([:width], controls[1].data)
    controls.each(&:clear_data)

    # BindingObject側からObservableを変更するが同じ値
    controls[1].width = 10
    controls.each {|control| assert_equal([], control.data)}
    controls.each(&:clear_data)
    
    # BindingObjectを削除
    controls[1].unbind(:width)
    observable.value = 0
    controls.each {|control| assert_equal([], control.data)}
    assert_equal(0, observable.instance_eval { @observers.size })
    controls.each(&:clear_data)
    
    # 値が割り当てられている際にunbind
    controls[1].width = 10
    assert_equal(0, observable.value)
    controls[1].unbind(:width)
    assert_nil(controls[1].width)
    
    # おわり
    controls[1].finalize
  end

  def test_observable_collection
    observable = Itefu::Layout::ObservableObject.new([1,2])
    assert_instance_of(Itefu::Layout::ObservableCollection, observable)
    assert_equal(1, observable[0])
    assert_equal(2, observable[1])

    control = TestBindingControl.new
    control.clear_data
    control.height = control.binding { observable }
    assert_equal(1, observable.instance_eval { @observers.size })
    assert_equal([:height], control.data)
    control.clear_data
    
    # コレクションの要素のみを変更
    observable[0] = 10
    assert_equal([:height], control.data)
    control.clear_data

    # コレクションの要素を変更するが値は同じ
    observable[0] = 10
    assert_equal([], control.data)
    control.clear_data
  end

end
