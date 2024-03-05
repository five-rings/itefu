=begin
  処理時間の計測を行う  
=end  
module Itefu::Aspect::Profiler
  
  # 新しいシーンの追加にかかる時間を計測する
  def self.enable_scene_manager
    splittimer = Itefu::Debug::SplitTimer.new("scene")

    # 新しいシーンの追加を始める
    Itefu::Aspect.add_advice Itefu::Scene::Manager, :push_new_scenes do |caller|
      if caller.this.next_scene.available?
        splittimer.start("----- new scenes -----")
      end
      caller.()
    end

    # シーンのインスタンスを生成
    Itefu::Aspect.add_advice Itefu::Scene::Manager, :create_instance do |caller|
      instance = caller.()
      splittimer.check(instance.class.to_s)
    end
  end
  
  # Layout::Viewの読み込みにかかる時間を計測する
  def self.enable_layout_view
    splittimer = Itefu::Debug::SplitTimer.new("layout")
    
    # レイアウトの読み込み全体
    Itefu::Aspect.add_advice Itefu::Layout::View, :load_layout do |caller|
      splittimer.start
      caller.()
      splittimer.check("layout loaded")
    end
  end


  # 毎フレームの処理負荷を計測する
  module PerformanceCounter
    extend Itefu::Aspect
    
    # PerformanceCounterの初期化
    # Scene
    advice Itefu::Scene::Manager, :on_initialize do |caller|
      if pc = caller.this.manager.system(Itefu::Debug::Performance::Manager)
        pc.add_counter(:scene_initialize, Itefu::Color.Yellow)
        pc.add_counter(:scene_update, Itefu::Color.Red)
        pc.add_counter(:scene_draw, Itefu::Color.Blue)
      end
      caller.()
    end
    # Sound
    advice class_method Itefu::Sound::Manager, :initialize do |caller, manager|
      if pc = manager.system(Itefu::Debug::Performance::Manager)
        caller.this.instance_variable_set(:@manager, manager)
        pc.add_counter(:sound, Itefu::Color.Gold)
      end
      caller.()
    end
    
    # 新しいシーンの生成
    advice Itefu::Scene::Manager, :push_new_scenes do |caller|
      if pc = caller.this.manager.system(Itefu::Debug::Performance::Manager)
        pc.counter(:scene_initialize).measure { caller.() }
      else
        caller.()
      end
    end
    
    # シーンの更新処理
    advice Itefu::Scene::Manager, :update_scenes do |caller|
      if pc = caller.this.manager.system(Itefu::Debug::Performance::Manager)
        pc.counter(:scene_update).measure { caller.() }
      else
        caller.()
      end
    end
    
    # シーンの描画処理
    advice Itefu::Scene::Manager, :draw_scenes do |caller|
      if pc = caller.this.manager.system(Itefu::Debug::Performance::Manager)
        pc.counter(:scene_draw).measure { caller.() }
      else
        caller.()
      end
    end
    
    # サウンドの更新
    advice class_method Itefu::Sound::Manager, :update do |caller|
      manager = caller.this.instance_variable_get(:@manager)
      if pc = manager.system(Itefu::Debug::Performance::Manager)
        pc.counter(:sound).measure { caller.() }
      else
        caller.()
      end
    end
  end

end
