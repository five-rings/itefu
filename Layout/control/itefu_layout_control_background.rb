=begin
  Layoutシステム/背景描画を行いたいコントロールにmix-inする
=end
module Itefu::Layout::Control::Background
  extend Itefu::Layout::Control::Bindable::Extension
  include Itefu::Layout::Control::Drawable
  attr_bindable :background   # [Color|ImageData|Proc] 背景に描画する内容
  attr_bindable :fill_padding # [Boolean] padding領域を塗りつぶすか

  # 背景にはりつける画像のデータ
  ImageData = Struct.new(:id, :stretch, :opacity, :hflip, :vflip)

  
  def self.extended(object)
    if object.is_a?(Itefu::Layout::Control::Resource)
      # Control::Resourceが既にあればそれを使う
      object.extend LoadImage
    else
      # 必要になるまで何もしない
      object.extend LoadImageProxy
    end
  end

  def self.included(klass)
    # raise "Control::Resource is not included in #{klass}" unless klass.include?(Itefu::Layout::Control::Resource)
    if klass.include?(Itefu::Layout::Control::Resource)
      klass.instance_eval { include LoadImage }
    else
      # 必要になるまで何もしない
      klass.instance_eval { include LoadImageProxy }
    end
  end

  # load_imageが使用された時点でControl::Resourceをextendする
  module LoadImageProxy
    def load_bg_image(*args)
      self.extend Itefu::Layout::Control::Resource
      self.extend LoadImage
      load_bg_image(*args)
    end
  end
  
  # Control::Resourceを使用してImageDataを作成する
  module LoadImage
    # @param [String] filename 読み込む画像のファイル名
    # @param [Boolean] stretch 画像を表示範囲に合わせて伸縮するか
    # @param [Fixnum] opacity 負透明度 [0xff-0], 0xffで不透明, 0で透明
    # @param [Boolean] hflip 左右反転するか
    # @param [Boolean] vflip 上下反転するか
    def load_bg_image(filename, stretch = nil, opacity = nil, hflip = nil, vflip = nil)
      ImageData.new(load_image(filename), stretch||false, opacity||0xff, hflip||false, vflip||false)
    end
  end

  # 再整列不要の条件
  def stable_in_placement?(name)
    case name
    when :background, :fill_padding
      true
    else
      super
    end
  end

  # 再描画不要の条件
  def stable_in_appearance?(name)
    super
  end
  
  # 背景を描画する
  def draw_control(target)
    bitmap = target.buffer
    bg = self.background
    if self.fill_padding
      x = drawing_position_x - padding.left
      y = drawing_position_y - padding.top
      w = actual_width
      h = actual_height
    else
      x = drawing_position_x
      y = drawing_position_y
      w = content_width
      h = content_height
    end

    case bg
    when Color
      # 色を塗る
      draw_background_color(bitmap, x, y, w, h, bg)
    when ImageData
      # 画像を貼り付ける
      draw_background_image(bitmap, x, y, w, h, bg)
    when Proc
      # ユーザ定義の描画方法を用いる
      bg.call(self, bitmap, x, y, w, h)
    end if bitmap

    super
  end

  # 指定した領域を単色で塗りつぶす
  def draw_background_color(bitmap, x, y, w, h ,bg)
    if bg.alpha < 0xff
      # fill_rectだと先に描画された内容を消してしまうので半透明の場合はbltする
      Itefu::Rgss3::Bitmap.empty.set_pixel(0, 0, bg)
      bitmap.stretch_blt(
        Itefu::Rgss3::Rect::TEMPs[0].set(x, y, w, h),
        Itefu::Rgss3::Bitmap.empty,
        Itefu::Rgss3::Rect::TEMPs[1].set(0, 0, 1, 1)
      )
      Itefu::Rgss3::Bitmap.empty.clear
    else
      # 不透明で塗る場合はfill_rectで塗りつぶす
      bitmap.fill_rect(x, y, w, h, bg)
    end
  end

  # 画像を指定した領域に描画する
  def draw_background_image(bitmap, x, y, w, h, bg)
    image = data(bg.id)
    imgw = bg.stretch ? image.width : w 
    imgh = bg.stretch ? image.height : h 
    bitmap.stretch_blt(
      Itefu::Rgss3::Rect::TEMPs[0].set(x, y, w, h),
      image,
      Itefu::Rgss3::Rect::TEMPs[1].set(
        bg.hflip ? imgw : 0,
        bg.vflip ? imgh : 0,
        bg.hflip ? -imgw : imgw,
        bg.vflip ? -imgh : imgh),
      bg.opacity)
  end

end
