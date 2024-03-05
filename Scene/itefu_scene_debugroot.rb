=begin
  デバッグメニュー用のルートシーン
=end
class Itefu::Scene::DebugRoot < Itefu::Scene::Base

  def root_scene
    Itefu::TestScene::Menu
  end

  def on_initialize
    @page_stack = []
    push_scene(root_scene)
  end
  
  def on_resume(old_scene)
    # 画面遷移を記録して、シーンから抜けたとき、自動的に前のシーンに戻るようにする
    if manager.next_scene.available?
      # 次のシーンへ進む
      next_page = Itefu::Scene::Manager::NextSceneInfo.new
      next_page.klass = old_scene.class
      next_page.args  = old_scene.respond_to?(:args)  && old_scene.args
      next_page.block = old_scene.respond_to?(:block) && old_scene.block
      @page_stack << next_page
    else
      # 前のシーンへ戻る
      prev_page = @page_stack.pop
      if prev_page && prev_page.available?
        push_scene(prev_page.klass, *prev_page.args, &prev_page.block)
      else
        quit
      end
    end
  end

end
