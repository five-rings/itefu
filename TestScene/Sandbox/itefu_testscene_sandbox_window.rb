=begin
  テスト用のScene/Windowの処理負荷を確認する
=end
class Itefu::TestScene::Sandbox::Window < Itefu::Scene::Base
  def on_initialize
    @window = Itefu::Rgss3::Window.new(0, 0, 128, 128)
    @window.contents.fill_rect(@window.contents.rect, Itefu::Color.Red)
    @window.openness = 0xff
    
    @value_x = @value_y = 2
  end
  
  def on_finalize
    @window = @window.swap(nil)
  end
  
  def on_update
#    change_window_xy
#    move_window
    set_window_size
    @value_x *= -1 if @window.x <= 0 || @window.x >= (Graphics.width - @window.width)
    @value_y *= -1 if @window.y <= 0 || @window.y >= (Graphics.height - @window.height)
    @window.update
  end
  
  def change_window_xy
    # x/y の変更だけなら大して処理負荷はかからない
    @window.x += @value_x
    @window.y += @value_y
  end
  
  def move_window
    # width/height も設定するため, 処理負荷が大きい
    @window.move(@window.x + @value_x, @window.y + @value_y, @window.width, @window.height)
  end
  
  def set_window_size
    # width/height の大きさに応じて, 処理負荷が大きくなる
    @window.width = @window.width
    @window.height = @window.height
  end

end
