=begin
  指定フレーム待って終了するシーン
=end
class Itefu::Scene::Wait < Itefu::Scene::Base

  def on_initialize(wait_count)
    @wait_count = wait_count
  end

  def on_update
    if @wait_count <= 0
      quit
    end

    @wait_count -= 1
  end

end
