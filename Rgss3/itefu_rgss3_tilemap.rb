=begin
  RGSS3のTilemapの拡張
=end
class Itefu::Rgss3::Tilemap < Tilemap
  include Itefu::Rgss3::Resource
  DEFAULT_CELL_SIZE = Itefu::Tilemap::DEFAULT_CELL_SIZE
  DEFAULT_SHADOW_COLOR = Itefu::Tilemap::DEFAULT_SHADOW_COLOR

  # セルサイズ
  def cell_width; DEFAULT_CELL_SIZE; end
  def cell_height; DEFAULT_CELL_SIZE; end
  def cell_width=(v); raise Itefu::Exception::NotSupported; end
  def cell_height=(v); raise Itefu::Exception::NotSupported; end
  
  # 影の色
  def shadow_color; DEFAULT_SHADOW_COLOR; end
  def shadow_color(v); raise Itefu::Exception::NotSupported; end

  # @return [Fixnum] このタイルマップの幅
  def screen_width
    self.viewport && self.viewport.rect.width || Graphics.width
  end

  # @return [Fixnum] このタイルマップの高さ
  def screen_height
    self.viewport && self.viewport.rect.height|| Graphics.height
  end


  def initialize(vp = nil)
    # @note self.viewport=が呼ばれないので明示的にカウントを上げる
    vp.ref_attach if vp
    super
  end

  def viewport=(vp)
    super(Itefu::Rgss3::Resource.swap(self.viewport, vp))
  end

  def impl_dispose
    super
    self.viewport = nil
  end
  
  def reset_resource_properties(vp = nil)
    # 使いまわせるかよくわからないのと、需要もないように思えるので、ひとまず未対応としている
    raise Itefu::Exception::NotSupported
  end

end
