=begin
  Layoutシステiム/Selectorから選択可能な項目
=end
module Itefu::Layout::Control::Selectable
  include Itefu::Layout::Control::Callback
  attr_accessor :unselectable
  def selectable?; unselectable.!; end
  def unselectable?; unselectable; end

  def select_activate
    execute_callback(:select_activated)
  end
  
  def select_deactivate
    execute_callback(:select_deactivated)
  end
  
  def select_suspend
    execute_callback(:select_suspended)
  end
  
  def select_decide
    execute_callback(:select_decided)
  end
  
  def select_cancel
    execute_callback(:select_canceled)
  end
end

# Selectableを選択不可能にしたいときにmix-inする
module Itefu::Layout::Control::Unselectable
  def self.new(parent, klass, *args)
    instance = klass.new(parent, *args)
    instance.extend Itefu::Layout::Control::Unselectable
    instance
  end

  def unselectable; true; end
  def selectable?; false; end
  def unselectable?; true; end
private
  def unselectable=(value); end
end

# Visibilityに応じて選べるかどうかが代わるようにする
module Itefu::Layout::Control::SelectableIfVisible
  def self.new(parent, klass, *args)
    instance = klass.new(parent, *args)
    instance.extend Itefu::Layout::Control::Unselectable
    instance
  end

  def unselectable
    Itefu::Layout::Definition::Visibility.visible?(self.visibility).!
  end
private
  def unselectable=(value); end
end


