=begin
  指定秒数待機するだけのアニメーション
=end
class Itefu::Animation::Wait < Itefu::Animation::Base
  
  def on_initialize(wait_count)
    @wait_count = wait_count
  end
  
  def on_update(delta)
    finish if @play_count >= @wait_count
  end

end
