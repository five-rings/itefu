=begin
  Layoutシステム/フォント描画機能を持つコントロールにmix-inして使用する
=end
module Itefu::Layout::Control::Font
  include Itefu::Layout::Definition
  extend Itefu::Layout::Control::Bindable::Extension
  attr_bindable :font_name        # [String] フォント名
  attr_bindable :font_size        # [Fixnum] 文字の大きさ
  attr_bindable :font_bold        # [Boolean] 太字にするか
  attr_bindable :font_italic      # [Boolean] 斜体にするか
  attr_bindable :font_outline     # [Boolean] 枠をつけるか
  attr_bindable :font_shadow      # [Boolean] 影をつけるか
  attr_bindable :font_color       # [Color] フォントの色
  attr_bindable :font_out_color   # [Color] フォントの枠の色
  attr_reader :font               # [Font] フォントの属性を何も指定していない場合はnil

  # デフォルトに戻すとき用のフォント
  DEFAULT_FONT = Font.new
  
  # 外部で生成されたフォント情報を共用する
  # @note 共用している場合に font_xxx を変更すると元のフォントも変更してしまうので注意
  def apply_font(new_font)
    @font = new_font
  end

  # フォントが変更された際の処理
  # @param [Symbol] name attr_bindableで定義された属性名
  # @param [String] attribute 対応するFontの属性
  def font_changed(name, attribute)
    @font ||= Font.new
    @font.send("#{attribute}=", self.send(name))
  end

  # 属性更新時の処理
  def binding_value_changed(name, old_value)
    if /^font_(.+)$/ === name
      font_changed(name, $1)
    end
    super
  end

  # 再整列不要の条件
  def stable_in_placement?(name)
    case name
    when :font_color, :font_out_color
      # 色は配置に関係しない
      true
    when :font_name, :font_size, :font_bold, :font_italic, :font_outline, :font_shadow
      # サイズが指定されているなら文字がかわっても変更されない
      (width != Size::AUTO) && (height != Size::AUTO)
    else
      super
    end
  end

  # 描画前にフォントを適用し、終了後にフォントを元に戻す
  # @param [Itefu::Rgss3::Bitmap] bitmap フォントを適用するbitmap
  # @param [Font] font_to_apply 一時的に適用するフォント
  # @yield 任意のブロックを実行した後フォントを元に戻す
  # @note font_to_applyにnilを指定すると何もせずにブロックを実行する
  def use_bitmap_applying_font(bitmap, font_to_apply)
    return unless bitmap
    
    # bitmap.fontにFontを代入すると、オブジェクトを入れ替えず、各プロパティをコピーしてしまう
    # そのためフォントを設定していない場合は、デフォルトフォントを明示的に指定する
    bitmap.font = font_to_apply || DEFAULT_FONT
    yield(bitmap)
  end

  # @return [Itefu::Rgss3::Bitmap::TextAlignment] Layoutのアラインメントをrgssのものに変換して返す
  def text_horizontal_alignment(halign = nil)
    case halign || horizontal_alignment
    when Alignment::LEFT
      Itefu::Rgss3::Bitmap::TextAlignment::LEFT
    when Alignment::RIGHT
      Itefu::Rgss3::Bitmap::TextAlignment::RIGHT
    else  # center, stretch
      Itefu::Rgss3::Bitmap::TextAlignment::CENTER
    end
  end
  
end
