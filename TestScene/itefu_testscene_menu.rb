=begin
  テスト用のSceneを選ぶメニュー
=end
class Itefu::TestScene::Menu < Itefu::Scene::DebugMenu
  
  def caption
    "DebugMenu"
  end
  
  module Animation
    include Itefu::TestScene::Animation
    def self.add_menu(m)
      m.add_item("Anime/Effect",    Effect)
      m.add_item("Anime/KeyFrame",  KeyFrame)
      m.add_item("Anime/Composite", Composite)
    end
  end

  module Sound
    include Itefu::TestScene::Sound
    def self.add_menu(m)
      m.add_item("Sound/BGM",  BGM)
      m.add_item("Sound/BGS",  BGS)
      m.add_item("Sound/ME",   ME)
      m.add_item("Sound/SE",   SE)
      m.add_item("Sound/Environment", Environment)
    end
  end
  
  module SceneGraph
    include Itefu::TestScene::SceneGraph
    def self.add_menu(m)
      m.add_item("SceneGraph/Sprite", Sprite)
      m.add_item("SceneGraph/HitTest", HitTest)
    end
  end
  
  module Tilemap
    include Itefu::TestScene::Tilemap
    def self.add_menu(m)
      m.add_item("Tilemap/Default", Default)
      m.add_item("Tilemap/Redraw", Redraw)
      m.add_item("Tilemap/Predraw", Predraw)
    end
  end
  
  def menu_list(m)
    Animation.add_menu(m)
    m.add_separator
    Sound.add_menu(m)
    m.add_separator
    SceneGraph.add_menu(m)
    m.add_separator
    Tilemap.add_menu(m)
    m.add_separator
    m.add_item("Layout", Itefu::TestScene::Layout::List, "../code/script/itefu/testscene/layout/sample")
  end
  
  def on_item_selected(index, m, *args)
    case m
    when ::Proc, ::Method
      m.call(*args)
    else
      switch_scene(m, *args)
    end
  end

end
