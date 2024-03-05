=begin
  テスト用のScene/スプライト移動の処理負荷を確認する
=end
class Itefu::TestScene::Sandbox::Sprite < Itefu::Scene::Base
  def on_initialize
    @sprite = Itefu::Rgss3::Sprite.new
    Itefu::Rgss3::Bitmap.new(128, 128).auto_release do |bitmap|
      @sprite.bitmap = bitmap
    end
    @sprite.bitmap.fill_rect(@sprite.src_rect, Itefu::Color.Red)
    
    @value_x = @value_y = 2
  end
  
  def on_finalize
    @sprite = @sprite.swap(nil)
  end
  
  def on_update
    # スプライトを移動しても大して負荷はかからない
    @sprite.x += @value_x
    @sprite.y += @value_y
    @value_x *= -1 if @sprite.x <= 0 || @sprite.x >= (Graphics.width - @sprite.width)
    @value_y *= -1 if @sprite.y <= 0 || @sprite.y >= (Graphics.height - @sprite.height)
    @sprite.update
  end

end
