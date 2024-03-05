=begin
  Animationのテストコード
=end
class Itefu::Test::Animation < Itefu::UnitTest::TestCase

  class TestPlayer
    include Itefu::Animation::Player
    def update
      update_animations
    end
  end
  
  class TestAnime < Itefu::Animation::Base
    attr_reader :data
    def clear_data; data.clear; end
    def on_initialize; @data = [:initialize]; end
    def on_finalize; data.push :finalize; end
    def on_update(delta); data.push :update; end
    def on_start(player); data.push :start; end
    def on_finish; data.push :finish; end
    def on_pause; data.push :pause; end
    def on_resume; data.push :resume; end
  end

  def test_player
    player = TestPlayer.new

    assert_nil(player.animation(:test))
    assert(player.playing_animation?(:test).!)
    player.pause_animations
    player.resume_animations

    anime1 = TestAnime.new
    anime2 = TestAnime.new
    anime3 = TestAnime.new
    
    assert_same(anime1, player.play_animation(:test, anime1))
    assert(player.playing_animation?(:test))
    assert(anime1.playing?)
    assert(player.playing_animations?)

    # 別のIDで登録できる
    assert_same(anime2, player.play_animation(:test2, anime2))
    assert(player.playing_animation?(:test2))
    assert(anime2.playing?)
    assert(player.playing_animations?)

    # 再生中のアニメを同じIDで再生 (再生しなおされる)
    assert_same(anime2, player.play_animation(:test2, anime2))
    assert(player.playing_animation?(:test2))
    assert(anime2.playing?)
    assert(player.playing_animations?)

    # 再生中のアニメを別のIDで再登録
    assert_nil(player.play_animation(:test22, anime2))
    assert(anime2.playing?)
    assert(player.playing_animation?(:test2))
    assert(player.playing_animations?)

    # 強制上書き
    assert_same(anime3, player.play_animation(:test, anime3))
    assert(player.playing_animation?(:test))
    assert(anime1.playing?.!)
    assert(anime3.playing?)
    assert(player.playing_animations?)
    
    # 再生終了したものの除外
    assert(anime2.playing?)
    assert(player.animation(:test2))
    anime2.finish
    player.update_animations
    assert(anime2.playing?.!)
    assert(player.animation(:test2).!)
    assert(player.playing_animations?)
    
    # 終了処理
    assert(player.animation(:test))
    player.finalize_animations
    assert(player.animation(:test).!)
    assert(anime3.playing?.!)
    assert(player.playing_animations?.!)
  end
  
  def test_player_adding_in_iteration
    # イテレーション中にアニメーションを追加するテスト
    player = TestPlayer.new
    anime2 = TestAnime.new
    anime1 = TestAnime.new.finisher {
      player.play_animation(:test2, anime2)
    }.updater { anime1.finish }
    # anime1を再生
    player.play_animation(:test1, anime1)
    assert(anime1.playing?)
    player.update_animations
    # anime1のfinisherでanime2が再生されているのを確認
    assert(anime2.playing?)
    player.finalize_animations
  end
  
  def test_anime_base
    player = TestPlayer.new

    # 生成
    animes = 2.times.map { TestAnime.new.tap {|anime|
      anime.starter {
        anime.data.push :started
      }.finisher {
        anime.data.push :finished
      }.updater {
        anime.data.push :updated
      }.auto_finalize
    } }
    animes.each.with_index do |anime, index|
      assert_equal([:initialize], anime.data)
      assert(anime.playing?.!)
      anime.clear_data
    end
    
    animes.each.with_index do |anime, index|
      assert_same(anime, player.play_animation(:"test#{index}", anime))
      assert_equal([:start, :started], anime.data)
      assert(anime.playing?)
      anime.clear_data
    end

    # 再生
    player.update_animations
    animes.each.with_index do |anime, index|
      assert_equal([:update, :updated], anime.data)
      assert_equal(1, anime.instance_eval { @play_count })
      anime.clear_data
    end

    # ポーズ
    player.pause_animations
    animes.each.with_index do |anime, index|
      assert(anime.paused?)
      assert(anime.playing?)
      assert_equal([:pause], anime.data)
      anime.clear_data
    end

    # ポーズ中の再生
    player.update_animations
    animes.each.with_index do |anime, index|
      assert_equal([], anime.data)
      assert_equal(1, anime.instance_eval { @play_count })
      anime.clear_data
    end

    # 再開
    player.resume_animations
    animes.each.with_index do |anime, index|
      assert(anime.paused?.!)
      assert(anime.playing?)
      assert_equal([:resume], anime.data)
      anime.clear_data
    end

    # 再開後の再生
    player.update_animations
    animes.each.with_index do |anime, index|
      assert_equal([:update, :updated], anime.data)
      assert_equal(2, anime.instance_eval { @play_count })
      anime.clear_data
    end

    # 終了
    player.finalize_animations
    animes.each.with_index do |anime, index|
      assert_equal([:finish, :finished, :finalize], anime.data)
      assert(anime.playing?.!)
      anime.clear_data
    end
    
    # 破棄
    animes.each.with_index do |anime, index|
      anime.finalize
      assert_equal([:finalize], anime.data)
      assert(anime.playing?.!)
      anime.clear_data
    end
  end
  
  def test_keyframe_animation
    player = TestPlayer.new
    player.animation_speed = 10

    target = Struct.new(:linear, :begin, :end, :triggered).new

    anime = Itefu::Animation::KeyFrame.new
    anime.instance_eval do
      add_key  0, :linear,   0.0, linear
      add_key 60, :linear, 100.0
      add_key  0, :begin,    0, step_begin
      add_key 60, :begin,  100
      add_key  0, :end,      0, step_end
      add_key 60, :end,    100
      add_trigger(29) { target.triggered = true }
      max_frame 100
    end
    anime.default_target = target
    player.play_animation(:test, anime)

    # 1回目は0フレーム目の状態になる
    1.times { player.update_animations }
    assert_equal(0, target.linear)
    assert_equal(0, target.begin)
    assert_equal(100, target.end)
    assert(target.triggered.!)

    # 補完できているか確認
    1.times { player.update_animations }
    assert_in_delta(100 * 10 / 60.0, target.linear)
    assert_equal(0, target.begin)
    assert_equal(100, target.end)
    assert(target.triggered.!)

    # triggerをまたぐ
    2.times { player.update_animations }
    assert_in_delta(100 * 30 / 60.to_f, target.linear)
    assert_equal(0, target.begin)
    assert_equal(100, target.end)
    assert(target.triggered)

    # add_key で指定したフレームを超える
    3.times { player.update_animations }
    assert_equal(100, target.linear)
    assert_equal(100, target.begin)
    assert_equal(100, target.end)
    assert(anime.playing?)
    
    # max_frame の直前
    3.times { player.update_animations }
    assert_equal(100, target.linear)
    assert_equal(100, target.begin)
    assert_equal(100, target.end)
    assert(anime.playing?)

    # max_frame分再生し終わった
    1.times { player.update_animations }
    assert_equal(100, target.linear)
    assert_equal(100, target.begin)
    assert_equal(100, target.end)
    assert(anime.playing?.!)

    player.finalize_animations
    anime.finalize
  end
  
  # ループのテスト
  def test_keyframe_animation_loop
    player = TestPlayer.new

    target = Struct.new(:value, :triggered).new(0, 0)
    anime = Itefu::Animation::KeyFrame.new
    anime.instance_eval do
      loop true
      default_curve linear
      add_key  0, :value,   0
      add_key 10, :value, 100
      add_trigger(5) { target.triggered += 1 }
    end
    anime.default_target = target
    player.play_animation(:test, anime)

    # triggerをまたぐ前
    2.times { player.update_animations }
    assert_in_delta(100 * 1 / 10.to_f, target.value)
    assert_equal(0, target.triggered)
    
    # loopする直前/triggerをまたいだ
    8.times { player.update_animations }
    assert_in_delta(100 * 9 / 10.to_f, target.value)
    assert_equal(1, target.triggered)

    # loopした
    1.times { player.update_animations }
    assert_equal(0, target.value)
    assert_equal(1, target.triggered)

    # 二度目のtriggerの直前
    4.times { player.update_animations }
    assert_equal(1, target.triggered)

    # triggerをまたいだ
    1.times { player.update_animations }
    assert_equal(2, target.triggered)
    
    player.finalize_animations
    anime.finalize
  end
  
  # 再生中に中断した際のテスト
  def test_keyframe_animation_abortion
    player = TestPlayer.new

    target = Struct.new(:value, :triggered).new
    anime = Itefu::Animation::KeyFrame.new
    anime.instance_eval do
      add_key  0, :value,   0, linear
      add_key 10, :value, 100
      add_trigger(5) { target.triggered = true }
    end
    anime.default_target = target
    player.play_animation(:test, anime)

    2.times { player.update_animations }
    assert_in_delta(100 * 1 / 10.to_f, target.value)
    assert(target.triggered.!)

    # 中断
    anime.finish
    assert_equal(100, target.value)
    assert(target.triggered)

    player.finalize_animations
    anime.finalize
  end
  
  # 再生速度が1未満の場合のテスト
  def test_keyframe_animation_duplicated_framecount
    player = TestPlayer.new

    target = Struct.new(:value, :triggered).new(0, 0)
    anime = Itefu::Animation::KeyFrame.new
    anime.instance_eval do
      speed 1, 2
      add_key  0, :value,   0, linear
      add_key  2, :value, 100
      add_trigger(1) { target.triggered += 1 }
    end
    anime.default_target = target
    player.play_animation(:test, anime)

    # 0/2
    1.times { player.update_animations }
    assert_equal(0, target.value)
    assert_equal(0, target.triggered)

    # 1/2
    1.times { player.update_animations }
    assert_in_delta(100 * 1 / 4.to_f, target.value)
    assert_equal(0, target.triggered)

    # 2/2, triggerをまたぐ
    1.times { player.update_animations }
    assert_in_delta(100 * 2 / 4.to_f, target.value)
    assert_equal(1, target.triggered)

    # 3/2, triggerが二度呼ばれないことを確認する
    1.times { player.update_animations }
    assert_in_delta(100 * 3 / 4.to_f, target.value)
    assert_equal(1, target.triggered)

    # 4/2, 再生終了
    1.times { player.update_animations }
    assert_in_delta(100, target.value)
    assert_equal(1, target.triggered)
    assert(anime.playing?.!)

    player.finalize_animations
    anime.finalize
  end
  
  # トリガーのテスト
  def test_keyframe_animation_trigger
    player = TestPlayer.new

    target = Struct.new(:triggered).new(0)
    anime = Itefu::Animation::KeyFrame.new
    anime.instance_eval do
      add_trigger(5) { target.triggered += 1 }

      # 開始フレームと同一点にある場合
      add_trigger(0) { target.triggered += 1 }
      
      # 終了フレームと同一点にある場合
      add_trigger(9) { target.triggered += 1 }
    end
    anime.default_target = target
    player.play_animation(:test, anime)

    # 終了直前まで動かす
    9.times { player.update_animations }
    assert_equal(2, target.triggered)
    assert(anime.playing?)

    # 再生終了
    1.times { player.update_animations }
    assert_equal(3, target.triggered)
    assert(anime.playing?.!)

    player.finalize_animations
    anime.finalize
  end
  
  # エフェクトのテスト
  def test_effect
    player = TestPlayer.new

    animations = load_data(Itefu::Rgss3::Filename::Data::ANIMATIONS)
    anime = Itefu::Animation::Effect.new(animations[1])

    # targetをアサインしていない
    assert_nil(player.play_animation(:test, anime))

    # targetをアサインする
    anime.assign_position(0, 0)
    assert_same(anime, player.play_animation(:test, anime))

    # Sprite, Bitmapが生成されているのを確認
    assert_equal(2, anime.instance_eval { @sprites.size })
    assert_instance_of(Itefu::Rgss3::Bitmap, anime.instance_eval { @bitmap1 })
    assert_nil(anime.instance_eval { @bitmap2 })

    # 再生終了するまで回す
    while anime.playing?
      player.update_animations
      Audio.se_stop
    end
    
    # Spriteが非表示になっていることを確認する
    assert(anime.instance_eval { @sprites.all? {|sprite| sprite.visible.! } })

    # targetをアサインする
    viewport = Itefu::Rgss3::Viewport.new
    target = Itefu::Rgss3::Sprite.new(viewport)
    assert_equal(2, viewport.ref_count)
    assert_equal(1, target.ref_count)
    anime.assign_target(target, viewport)
    assert_equal(3 + anime.instance_eval { @sprites.size }, viewport.ref_count)
    assert_equal(2, target.ref_count)

    # 別のアニメをアサインして再生    
    assert_same(anime, player.play_animation(:test, anime, animations[3]))

    # Sprite, Bitmapが生成されているのを確認
    assert_equal(5, anime.instance_eval { @sprites.size })
    assert_instance_of(Itefu::Rgss3::Bitmap, anime.instance_eval { @bitmap1 })
    assert_instance_of(Itefu::Rgss3::Bitmap, anime.instance_eval { @bitmap2 })

    # 中断する
    player.finalize_animations
    
    # Spriteが非表示になっているのを確認
    assert(anime.instance_eval { @sprites.all? {|sprite| sprite.visible.! } })

    # 破棄
    sprites = anime.instance_eval { @sprites }
    bitmaps = anime.instance_eval { [@bitmap1, @bitmap2] }
    anime.finalize

    # リソースの破棄を確認
    assert_equal(0, anime.instance_eval { @sprites.size })
    assert(sprites.all? {|sprite| sprite.disposed? })
    assert(bitmaps.all? {|bitmap| bitmap.disposed? })
    assert_nil(anime.instance_eval { @bitmap1 })
    assert_nil(anime.instance_eval { @bitmap2 })

    anime.finalize

    # 外部から与えたりソースの確認
    assert_equal(2, viewport.ref_count)
    assert_equal(1, target.ref_count)
    assert(target.disposed?.!)
    assert(viewport.disposed?.!)
    viewport.dispose
    assert(viewport.disposed?.!)
    target.dispose
    assert(target.disposed?)
    assert(viewport.disposed?)
  end
  
  # Compositeのテスト
  def test_composite
    player = TestPlayer.new

    anime_composite = Itefu::Animation::Composite.new
    animes = 2.times.map { anime_composite.add_animation(TestAnime).tap {|anime|
      anime.started = proc { anime.data.push :started }
      anime.finished = proc { anime.data.push :finished }
      anime.updated = proc { anime.data.push :updated }
    } }
    
    animes.each.with_index do |anime, index|
      assert_equal([:initialize], anime.data)
      assert(anime.playing?.!)
      anime.clear_data
    end

    assert_same(anime_composite, player.play_animation(:test, anime_composite))
    animes.each.with_index do |anime, index|
      assert_equal([:start, :started], anime.data)
      assert(anime.playing?)
      anime.clear_data
    end

    # 再生
    player.update_animations
    animes.each.with_index do |anime, index|
      assert_equal([:update, :updated], anime.data)
      assert_equal(1, anime.instance_eval { @play_count })
      anime.clear_data
    end

    # ポーズ
    player.pause_animations
    animes.each.with_index do |anime, index|
      assert(anime.paused?)
      assert(anime.playing?)
      assert_equal([:pause], anime.data)
      anime.clear_data
    end

    # ポーズ中の再生
    player.update_animations
    animes.each.with_index do |anime, index|
      assert_equal([], anime.data)
      assert_equal(1, anime.instance_eval { @play_count })
      anime.clear_data
    end

    # 再開
    player.resume_animations
    animes.each.with_index do |anime, index|
      assert(anime.paused?.!)
      assert(anime.playing?)
      assert_equal([:resume], anime.data)
      anime.clear_data
    end

    # 再開後の再生
    player.update_animations
    animes.each.with_index do |anime, index|
      assert_equal([:update, :updated], anime.data)
      assert_equal(2, anime.instance_eval { @play_count })
      anime.clear_data
    end

    # 終了
    player.finalize_animations
    animes.each.with_index do |anime, index|
      assert_equal([:finish, :finished], anime.data)
      assert(anime.playing?.!)
      anime.clear_data
    end
    
    # 破棄
    anime_composite.finalize
    animes.each.with_index do |anime, index|
      assert_equal([:finalize], anime.data)
      assert(anime.playing?.!)
      anime.clear_data
    end
  end

end
