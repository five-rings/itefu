=begin
  RGSS3のViewportの拡張
=end
class Itefu::Rgss3::Viewport < Viewport
  include Itefu::Rgss3::Resource
  
  # @return [Boolean] dispose済みか
  # @note なぜかRGSS3のデフォルト実装に用意されていないので独自実装する
  def disposed?
    begin
      # disposeされた後に呼ぶとエラーを起こすメソッドならなんでも良いので呼ぶ
      self.visible
      false
    rescue RGSSError
      true
    end
  end

  def reset_resource_properties(x, y, width, height)
    self.visible = false
    # 初期値に戻す
    self.rect.reset(0, 0, Graphics.width, Graphics.height)
    self.z = 0
    self.ox = self.oy = 0
    self.color.set(0, 0, 0, 0)
    self.tone.set(0, 0, 0, 0)
  end

end
