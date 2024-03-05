=begin
  Layoutシステム/カーソル選択の自動遷移を子に委譲する
=end
module Itefu::Layout::Control::SelectDelegation
  include Itefu::Layout::Definition
  include Itefu::Layout::Control::Intrusivable
#ifdef :ITEFU_DEVELOP
  extend Utility::Module.expect_for(Itefu::Layout::Control::Decorator)
#endif

  def unintrusivable?
    super || (@last_intrusived = intrusived_descendant).nil?
  end

  # フォーカスを引き受ける（ポインティングデバイス操作）
  def take_focus_by_selecting(owner, x, y)
    if @last_intrusived
      @last_intrusived.take_focus_by_selecting(owner, x, y)
    end
  end

  # フォーカスを引き受ける（キー操作）
  def take_focus_by_moving(owner, operation)
    if @last_intrusived
      @last_intrusived.take_focus_by_moving(owner, operation)
    end
  end


private

  # 子を辿って選択可能なものがないか探す
  def intrusived_descendant
    control = child
    while control
      case control
      when Itefu::Layout::Control::Decorator
        control = control.child
      when Itefu::Layout::Control::Intrusivable
        if control.unintrusivable?
          control = nil
        else
          break
        end
      else
        control = nil
      end
    end
    control
  end

end
