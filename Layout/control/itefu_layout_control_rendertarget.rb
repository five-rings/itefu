=begin
  Ｌａｙｏｕｔシステム/描画対象を持つコントロールにmix-inする
=end
module Itefu::Layout::Control::RenderTarget
  include Itefu::Layout::Control::DrawControl
  attr_accessor :contents_creation

#ifdef :ITEFU_DEVELOP
  @@debug_draw_boundary = true
  def self.debug_draw_boundary=(value)
    @@debug_draw_boundary = value
  end
  def debug_draw_boundary?
    @@debug_draw_boundary && root.debug?
  end
#endif
  
  # バッファを再生成する条件
  module ContentsCreation
    KEEP        = :keep         # 現在のまま保持する
    ALWAYS      = :force        # 整列したとき、常に再生成する
    IF_RESIZED  = :if_resized   # 以前とサイズが異なっていれば再生成する
    IF_LARGE    = :if_large     # 以前より大きければ再生性する
    IF_EMPTY    = :if_empty     # contentsが空なら再生成する
  end

  # @return [Rgss3::Bitmap] 描画可能なビットマップオブジェクト
  def buffer; raise Itefu::Layout::Definition::Exception::NotImplemented; end
  
  # @return [Rgss3::Viewport] 割り当てられたViewport
  def viewport; raise Itefu::Layout::Definition::Exception::NotImplemented; end
  
  # @return [Fixnum] Zインデックス
  def z; raise Itefu::Layout::Definition::Exception::NotImplemented; end

  # 再描画の必要があるか
  def corrupted?; @corrupted; end
  def draw_control_corrupted?; @corrupted; end
  
  # 再描画が必要な状態にする
  def be_corrupted; @corrupted = true; end
  
  # 再描画が必要な状態を解消する
  def resolve_corruption; @corrupted = false; end
  
  # レンダーターゲットは自分自身になる
  def render_target; self; end
  
  # 親階層の別のレンダーターゲット
  def parent_render_target; @render_target || parent && (@render_target = parent.render_target); end

  # @param [Boolean] 表示状態か
  # @note 上位コントロールが不可視の場合は, このコントロールの状態に関わらず, 非表示扱いとなる
  def shown?
    return @shown unless @shown.nil?
    if target = parent_render_target
      @shown = visible? && target.shown?
    else
      @shown = visible?
    end
  end

  def drawing_offset_x
    screen_x
  end
  
  def drawing_offset_y
    screen_y
  end
  
  # @return [Fixnum] コントロールのトポロジーからzを自動的に決定する
  def z_index
    if target = parent_render_target
      target.z + 1
    else
      1
    end
  end
  
  # 指定した型のrender_targetを探す
  def recent_ancestor(klass)
    t = self
    until t.nil? || klass === t
      t = t.parent_render_target
    end
    t
  end


private

  def impl_draw
    # 再描画が必要なら、描画処理の前に、バッファをクリアする
    if corrupted?
      buffer.clear if buffer
      super
#ifdef :ITEFU_DEVELOP
      draw_debug_boundary(self) if debug_draw_boundary?
#endif
      resolve_corruption
    else
      super
    end
  end

#ifdef :ITEFU_DEVELOP
  def draw_debug_boundary(target)
    return unless target && target.buffer
    target.buffer.fill_rect(              0,               0, actual_width,               1, Itefu::Color.Red)
    target.buffer.fill_rect(              0, actual_height-1, actual_width,               1, Itefu::Color.Red)
    target.buffer.fill_rect(              0,               1,            1, actual_height-2, Itefu::Color.Red)
    target.buffer.fill_rect( actual_width-1,               1,            1, actual_height-2, Itefu::Color.Red)
  end
#endif
end
