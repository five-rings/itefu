=begin
  Layoutシステム/フォーカスを得るコントロールにmix-inする
=end
module Itefu::Layout::Control::Focusable
  include Itefu::Focus::Focusable
  
  def focused_control; self; end
end
