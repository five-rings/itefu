=begin
  Layoutシステム/カーソル位置に画像を追従させる機能を追加する
=end
module Itefu::Layout::View::IconCursor
  include Itefu::Layout::Definition
  
  # @return [Itefu::Rgss3::Sprite] カーソルに表示するアイコンとして使用するSpriteを返す
  # @note 終了時に@spriteを解放しようとするので、外部から設定する場合は、リファレンスカウンタを上げておくこと
  def create_icon_cursor_sprite
    # サンプル兼デフォルト実装
    sprite = Itefu::Rgss3::Sprite.new
    Itefu::Rgss3::Bitmap.new(8, 8).auto_release {|bitmap|
      sprite.bitmap = bitmap
    }
    sprite.bitmap.fill_rect(sprite.bitmap.rect, Itefu::Color.Red)
    sprite.ox = 4
    sprite
  end
  
  def initialize(*args)
    super
    @@dummy_content ||= Itefu::Layout::Control::Alignmentable::DummyContent.new
    @sprite = create_icon_cursor_sprite
    ITEFU_DEBUG_ASSERT(@sprite.nil? || Itefu::Rgss3::Sprite === @sprite)
  end
  
  def finalize
    super
    @sprite = @sprite.swap(nil) if @sprite
  end
  
  def update_layout
    super
    if @sprite
      if focus.active? && (c = focus.current) && (fc = c.focused_control)
        # カーソルの合っているところへアイコンを移動する
        update_icon_cursor(fc)
        @sprite.visible = true
      else
        # カーソルがないので非表示にする
        @sprite.visible = false
      end
      @sprite.update
    end
  end
  
  # 指定したコントロールに合わせてカーソルアイコンを移動する
  def update_icon_cursor(control)
    align = case control
    when Itefu::Layout::Control::Alignmentable
      control.vertical_alignment
    end || Alignment::CENTER

    dummy = @@dummy_content
    dummy.content_width  = @sprite.bitmap.width
    dummy.content_height = @sprite.bitmap.height

    @sprite.y = Itefu::Layout::Control::Alignmentable.pos_y_alignmented(control, dummy, align)
    @sprite.x = control.content_left - dummy.content_width
  end

end
