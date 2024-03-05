=begin
  Sceneのテストコード
=end
class Itefu::Test::Scene < Itefu::UnitTest::TestCase

  class TestScene < Itefu::Scene::Base
    attr_reader :data
    def on_initialize(value)
      @data = [value]
    end
    def on_finalize; @data = :finalized; end
    def on_update; @data.push :updated; end
    def on_draw; @data.push :drawn; end
    def on_suspend(new_scene); @data = [:suspended]; end
    def on_resume(old_scene); @data = [:resumed]; end
    def on_not_resume(old_scene); @data = [:not_resumed]; end
  end

  def test_manager
    system_manager = Itefu::System::Manager.new(self)
    manager = system_manager.register(Itefu::Scene::Manager, TestScene, 10)
    scene = manager.scenes.last
    
    # 最初のSceneはupdateされるまでは追加されない
    assert_nil(scene)
    # update後の状態
    manager.update
    scene = manager.scenes.last
    assert_kind_of(TestScene, scene)
    assert_equal([10, :updated, :drawn], scene.data)
    assert(scene.alive?)
    assert(manager.running?)
    
    # さらにSceneが追加された状態
    manager.push(TestScene, :nomean)
    manager.update
    scene2 = manager.scenes.last
    assert_equal([:nomean, :updated, :drawn], scene2.data)
    assert_equal([:suspended, :updated, :drawn], scene.data)
    assert(scene.current?.!)
    assert(scene2.current?)
    assert(manager.running?)
    assert(scene.alive?)
    assert(scene2.alive?)
    
    # 前のカレントと入れ替わりで新しいＳｃｅｎｅが追加された状態
    scene2.quit
    manager.push(TestScene, "third")
    manager.update
    scene3 = manager.scenes.last
    assert_equal(:finalized, scene2.data)
    assert_equal(["third", :updated, :drawn], scene3.data)
    assert(scene.current?.!)
    assert(scene2.current?.!)
    assert(scene3.current?)
    assert(manager.running?)
    assert(scene.alive?)
    assert(scene2.dead?)
    assert(scene3.alive?)

    # 最上位のSceneが終了し元のSceneのみに戻った状態
    scene3.quit
    manager.update
    assert_equal(:finalized, scene3.data)
    assert_equal([:resumed, :updated, :drawn], scene.data)
    assert(scene.current?)
    assert(scene2.current?.!)
    assert(scene3.current?.!)
    assert(manager.running?)
    assert(scene.alive?)
    assert(scene2.dead?)
    assert(scene3.dead?)
    
    # 全てのSceneが終了した状態
    scene.quit
    manager.update
    assert_equal(:finalized, scene.data)
    assert(manager.running?.!)
    assert(scene.dead?)
    assert(scene2.dead?)
    assert(scene3.dead?)
    
    # quit後のresume
    scene.resume(nil)
    assert_equal([:not_resumed], scene.data)
    
    # その他
    assert_equal(self, manager.application)
    assert_equal(self, scene.application)
    assert_equal(self, scene2.application)
    assert_equal(self, scene3.application)
  end
  
end
