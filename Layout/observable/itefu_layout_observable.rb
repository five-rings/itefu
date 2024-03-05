=begin
  Layoutシステム/監視者を登録し変更時に通知する
=end
module Itefu::Layout::Observable
  attr_accessor :value

  def initialize(value)
    super
    @observers = []
    @value = value
  end
  
  def value=(new_value)
    @value = new_value
    notify_changed_value
  end
  
  def update(value)
    self.value = value
  end
  
  # 変更を監視者に通知する
  def notify_changed_value(force = false)
    @observers.delete_if(&:invalid?)
    if force
      @observers.each(&:notify_changed_forcibly)
    else
      @observers.each(&:notify_changed)
    end
  end
  
  def subscribe(binding_object)
    @observers << binding_object
  end

  # 保持しているオブジェクトに対して任意の操作を行い、結果にかかわらず変更を通知する
  def change(force = false)
    yield(@value) if block_given?
    notify_changed_value(force)
  end
  
  # 保持している値を変更し, 内容にかかわらず変更を通知する
  def modify(new_value)
    @value = new_value
    notify_changed_value(true)
  end

  # 自己代入
  def self_assign(operator, operand)
    self.value = @value.send(operator, operand)
  end

  def +(rhs); @value + rhs; end
  def -(rhs); @value - rhs; end
  def *(rhs); @value * rhs; end
  def /(rhs); @value / rhs; end
  def %(rhs); @value % rhs; end
  def **(rhs);@value ** rhs; end

end
