=begin
  ゲームシーンを管理するマネージャ
=end
class Itefu::Scene::Manager < Itefu::System::Base
  attr_reader :next_scene
  attr_reader :scenes

#ifdef :ITEFU_DEVELOP
  # 現在のシーン一覧を出力する
  def dump_log(out)
    Itefu::Debug::Log.notice "# scenes", out
    @scenes.each do |scene|
      Itefu::Debug::Log.notice "#{scene.class} (#{scene.object_id})", out
    end if @scenes
  end
#endif

  # @return [Boolean] 何らかのシーンを実行中か
  def running?
    @scenes.empty?.! || @next_scene.available?
  end

  # @return [Boolean] 指定したシーンがカレントシーン（最上位）か
  # @param [Scene::Base] scene チェックしたいシーンのインスタンス
  def current?(scene)
    @scenes.last.equal?(scene)
  end

  # 次のシーンを設定する
  # @param [Class] klass 次のシーンのクラスの型 (Scene::Baseを継承したもの)
  def push(klass, *args, &block)
    unless @next_scene.available? || @quit
      @next_scene.klass = klass
      @next_scene.args = args
      @next_scene.block = block
    end
  end
  
  # シーンを全て終了させる
  def quit
    unless @quit
      @quit = true
      @next_scene.clear
      @scenes.reverse_each(&:quit)
    end
  end


  # 次に遷移するシーンの情報
  class NextSceneInfo
    attr_accessor :klass, :args, :block
    # 情報をクリアする
    def clear; @klass = @args = @block = nil; end
    # 次のシーンが設定されているか
    def available?; @klass.nil?.!; end
  end


private

  def on_initialize(root_scene_klass, *args, &block)
    @scenes = []
    @next_scene = NextSceneInfo.new
    push(root_scene_klass, *args, &block)
  end
  
  def on_finalize
    @scenes.reverse_each(&:finalize)
    @scenes.clear
  end
  
  def on_update
#ifdef :ITEFU_DEVELOP
    return if Itefu::Debug.paused?
#endif
    pop_finished_scenes
    push_new_scenes
    update_scenes
    draw_scenes
  end
  
  def update_scenes 
    @scenes.each(&:update)
  end
  
  def draw_scenes
    @scenes.each(&:draw)
  end

  # 新しいシーンを追加する
  def push_new_scenes
    # initialize で push_scene されたとき @next_sceneが再び設定されるので while でまわす
    while @next_scene.available?
      klass = @next_scene.klass
      args = @next_scene.args
      block = @next_scene.block
      @next_scene.clear
      
      scene = @scenes.last
      current = create_instance(klass, *args, &block)
      @scenes << current
      scene.suspend(current) if scene
    end
  end

  # 終了したシーンを除去する
  def pop_finished_scenes
    if (scene = @scenes.last)
      until scene.alive?
        scene.finalize
        @scenes.pop
        current = @scenes.last
        break unless current
        current.resume(scene)
        scene = current
      end
    end
  end

  # インスタンス生成を無効化する
  # @note pushメソッドを変わりに使うこと
  private :create_instance

end
