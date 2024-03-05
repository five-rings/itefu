=begin
  ゲームシーンの基底クラス
=end
class Itefu::Scene::Base
  attr_reader :manager  # [Scene::Manager]

  # @return [Itefu::Application]
  def application; manager.application; end

  # @return [Boolean] シーンを実行中か
  def alive?; @alive; end

  # @return [Boolean] シーンが終了するか
  def dead?; alive?.!; end

  # シーンをぬける
  def quit; @alive = false; end

  # 次のシーンへ進む
  def push_scene(klass, *args, &block)
    manager.push(klass, *args, &block)
  end
  
  # 次のシーンへ切り替える
  def switch_scene(klass, *args, &block)
    manager.push(klass, *args, &block)
    quit
  end

  # @return [Boolean] カレントシーン（最上位）か？  
  def current?; manager.current?(self); end


private
  # --------------------------------------------------
  # 継承先で必要に応じてover-rideする

  # インスタンス生成時に一度だけ呼ばれる
  def on_initialize(*args); end
  
  # シーンを終了した後、インスタンス破棄前に一度だけ呼ばれる
  def on_finalize; end
  
  # 毎フレーム呼ばれる更新処理
  def on_update; end

  # 毎フレーム呼ばれる描画処理
  def on_draw; end

  # カレントシーンでなくなった際に呼ばれる
  # @param [Scene::Base] new_scene 新しくカレントになったシーン
  def on_suspend(new_scene); end
  
  # 再びカレントシーンになった際に呼ばれる
  # @param [Scene::Base] old_scene 前にカレントだったシーン
  # @warning 既にquitされている場合は呼ばれず、変わりにon_not_resumeが呼ばれる
  def on_resume(old_scene); end
  
  # 再びカレントシーンになったが既にquitしていた際に呼ばれる
  # @note 通常はfinalizeで後処理をすることを想定している
  # @note どうしてもfinalizeではなくresumeのタイミングで行いたい処理があるときに已む無く使う
  # @param [Scene::Base] old_scene 前にカレントだったシーン
  def on_not_resume(old_scene); end


public
  # --------------------------------------------------
  # 以下はScene::Managerから呼ばれる

  def initialize(manager, *args, &block)
    @alive = true
    @manager = manager
    on_initialize(*args, &block)
  end
  
  def finalize
    on_finalize
  end
  
  def update
    on_update if alive?
  end
  
  def draw
    on_draw if alive?
  end
  
  def suspend(new_scene)
    on_suspend(new_scene)
  end
  
  def resume(old_scene)
    if alive?
      on_resume(old_scene)
    else
      on_not_resume(old_scene)
    end
  end
  
end
