=begin
  Layoutシステム/ルートコントロール(デバッグ用)
=end
class Itefu::Layout::Control::Root::Debug < Itefu::Layout::Control::Root
  include Itefu::Layout::Control::SpriteTarget
  attr_accessor :debug
  def debug?; @debug; end

  # rootにparentはないので常にnilを返す
  def parent_render_target; nil; end

  def initialize(view)
    @debug = true
    # spriteのサイズは自動計算にする
    super(view, 0, 0)
  end

  # ビューワーなどで確認する用のサイズ設定を行う
  def design_size(w, h)
    size(w, h)
  end

end
