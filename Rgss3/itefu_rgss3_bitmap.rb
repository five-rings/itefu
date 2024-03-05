=begin
  RGSS3のBitmapの拡張
=end
class Itefu::Rgss3::Bitmap < Bitmap
  include Itefu::Rgss3::Resource

  # 左右の文字揃え
  module TextAlignment
    LEFT    = 0
    CENTER  = 1
    RIGHT   = 2
  end

  # サイズ計算などに使うための空のテンポラリバッファ
  @@empty_bitmap = nil

  # サイズ計算用
  OBLIQUE = Math.tan(Math::PI / 18.0)

  # @return [Itefu::Rgss3::Bitmap] テンポラリバッファ(空のBitmap)を取得する
  # @note 初回実行時にバッファを作成する
  def self.empty
    @@empty_bitmap ||= Itefu::Rgss3::Bitmap.new(32, 32)
  end

  # テンポラリバッファを削除する  
  def self.clear_empty
    @@empty_bitmap = Itefu::Rgss3::Resource.swap(@@empty_bitmap, nil)
  end
  
  # @return [Boolean] このインスタンスがテンポラリバッファ(空のBitmap)か
  def empty?
    self.equal?(@@empty_bitmap)
  end
  
  # colorに一時的にalphaを適用して描画する
  def fill_rect_alpha(alpha, *args)
    color = args[-1]
    old = color.alpha
    color.alpha = alpha
    fill_rect(*args)
    color.alpha = old
  end

  # @return [Rect] 装飾に対応した、文字の描画に必要なサイズを返す
  # @param [Boolean] to_draw 描画するときに必要な領域(true)か、サイズ計算に必要な領域(false)か
  def rich_text_size(text, to_draw = true)
    rect = text_size(text)

    # 枠つき
    if font.outline
      # @note 枠つきの場合, 幅を増やさないと, 自動的に縮小描画されてしまう
      # @warning あらゆるフォントで同じ値かは不明
      rect.width += to_draw ? 3 : 2
    end
    
    # 斜体
    if font.italic
      # @note 10度(π/18rad)傾斜させた場合の幅だけ広げている
      # @note ObliqueでなくItalicであればフォントにより異なるはずなので、正しくない値になることもあり得る
      rect.width += rect.height * OBLIQUE
    end

    rect
  end
  
  def reset_resource_properties(*args)
    # 初期値に戻す
    self.font = Font.new
  end

end
