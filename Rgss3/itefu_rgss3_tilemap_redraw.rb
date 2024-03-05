=begin
  Tilemap::Redrawの拡張
=end
class Itefu::Rgss3::Tilemap::Redraw < Itefu::Tilemap::Redraw
  include Itefu::Rgss3::Resource

  def viewport=(vp)
    super(Itefu::Rgss3::Resource.swap(self.viewport, vp))
  end

  def impl_dispose
    super
  end
  
  def reset_resource_properties(vp = nil)
    # 使いまわせるかよくわからないのと、需要もないように思えるので、ひとまず未対応としている
    raise Itefu::Exception::NotSupported
  end

end
