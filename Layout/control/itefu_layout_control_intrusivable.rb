=begin
  Layoutシステム/カーソル選択で侵入的に操作可能なコントロールにmix-inする  
=end
module Itefu::Layout::Control::Intrusivable
  attr_accessor :unintrusivable         # [Boolean] 子Selectorへの自動遷移を無効化する
  def unintrusivable?; @unintrusivable; end

  # フォーカスを引き受ける（ポインティングデバイス操作）
  def take_focus_by_selecting(owner, x, y)
    raise Itefu::Layout::Definition::Exception::NotImplemented
  end

  # フォーカスを引き受ける（キー操作）
  def take_focus_by_moving(owner, operation)
    raise Itefu::Layout::Definition::Exception::NotImplemented
  end
end
