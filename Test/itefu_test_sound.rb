=begin
  Soundのテストコード
=end
class Itefu::Test::Sound < Itefu::UnitTest::TestCase

  class TestSound
    include Itefu::Sound::SE
    include Itefu::Sound::ME
    include Itefu::Sound::BGM
    include Itefu::Sound::BGS
    
    def update
      update_me
      update_bgm
      update_bgs
    end
  end

  def test_se
    # 状態などを参照できないのでとりあえず呼べることだけ確認する
    sound = TestSound.new
    assert_instance_of(RPG::SE, sound.play_se("Decision1", 0))
    sound.stop_se
  end
  
  def test_me
    # 状態などを参照できないのでとりあえず呼べることだけ確認する
    sound = TestSound.new
    assert_instance_of(RPG::ME, sound.play_me("Gameover1", 0))
    sound.stop_me
  end
  
  def test_bgm
    sound = TestSound.new
    bgm = sound.play_bgm("Town1", 0)
    assert_instance_of(RPG::BGM, bgm)
    assert(sound.playing_bgm?)
    assert(sound.playing_bgm?(bgm))
    assert(sound.stopping_bgm?.!)
    
    # ボリューム変更
    sound.change_bgm_volume(1)
    assert_equal(1, sound.current_bgm.volume)
    sound.fade_bgm_volume(0)
    assert_equal(1, sound.current_bgm.volume)
    sound.update
    assert_equal(0, sound.current_bgm.volume)

    # 違うファイルを即再生
    bgm = sound.play_bgm_fade(0, "Town2", 0)
    assert(sound.playing_bgm?)
    assert(sound.playing_bgm?(bgm))
    assert(sound.stopping_bgm?.!)

    # 違うファイルをフェードをかけて再生
    bgm = sound.play_bgm_fade(50, "Town3", 0)
    assert(sound.playing_bgm?)
    assert(sound.playing_bgm?(bgm).!)
    assert(sound.stopping_bgm?)
    # 50ms経つまでは停止中のまま
    sound.update
    assert(sound.playing_bgm?)
    assert(sound.playing_bgm?(bgm).!)
    assert(sound.stopping_bgm?)
    sleep(0.1)
    # フェードが終わった
    sound.update
    assert(sound.playing_bgm?)
    assert(sound.playing_bgm?(bgm))
    assert(sound.stopping_bgm?.!)

    # フェードしながら停止
    sound.stop_bgm(50)
    assert(sound.playing_bgm?)
    assert(sound.stopping_bgm?)
    # 50ms経つまでは停止中のまま
    sound.update
    assert(sound.playing_bgm?)
    assert(sound.stopping_bgm?)
    sleep(0.1)
    # フェードが終わった
    sound.update
    assert(sound.playing_bgm?.!)
    assert(sound.stopping_bgm?.!)

    # 再生切り替え中に停止
    sound.play_bgm("Town1", 0)
    assert(sound.playing_bgm?)
    sound.play_bgm("Town2", 0)
    assert_not_nil(sound.instance_eval { @bgm_que })
    assert(sound.stopping_bgm?)
    sound.stop_bgm(1)
    assert(sound.playing_bgm?)
    assert(sound.stopping_bgm?)
    assert_nil(sound.instance_eval { @bgm_que })
    sleep(0.002)
    sound.update
    assert(sound.playing_bgm?.!)
    assert(sound.stopping_bgm?.!)

    # 音量フェード中に停止
    sound.play_bgm("Town1", 0)
    sound.fade_bgm_volume(1)
    sound.stop_bgm(1)
    assert(sound.playing_bgm?)
    assert(sound.stopping_bgm?)
    sleep(0.002)
    sound.update
    assert(sound.playing_bgm?.!)
    assert(sound.stopping_bgm?.!)
    
    # 停止中に再生
    sound.play_bgm("Town1", 0)
    sound.stop_bgm(1)
    assert(sound.playing_bgm?)
    assert(sound.stopping_bgm?)
    sound.play_bgm("Town2", 0)
    assert(sound.playing_bgm?)
    assert(sound.stopping_bgm?)
    sleep(0.1)
    sound.update
    assert(sound.playing_bgm?)
    assert(sound.stopping_bgm?.!)
    
    # 停止中に音量フェード
    sound.stop_bgm(1)
    assert(sound.playing_bgm?)
    assert(sound.stopping_bgm?)
    sound.fade_bgm_volume(1)
    assert(sound.playing_bgm?)
    assert(sound.stopping_bgm?)
    sleep(0.1)
    sound.update
    assert(sound.playing_bgm?.!)
    assert(sound.stopping_bgm?.!)

    # 音量フェード中に再生
    sound.play_bgm("Town1", 0)
    sound.fade_bgm_volume(1)
    bgm = sound.play_bgm_fade(1, "Town2", 0)
    assert(sound.playing_bgm?)
    assert(sound.playing_bgm?(bgm).!)
    assert(sound.stopping_bgm?)
    sleep(0.1)
    sound.update
    assert(sound.playing_bgm?)
    assert(sound.playing_bgm?(bgm))
    assert(sound.stopping_bgm?.!)

    # 音量フェード中に停止
    sound.fade_bgm_volume(1)
    sound.stop_bgm(1)
    assert(sound.playing_bgm?)
    assert(sound.stopping_bgm?)
    sleep(0.1)
    sound.update
    assert(sound.playing_bgm?.!)
    assert(sound.stopping_bgm?.!)
  end

  def test_bgs
    sound = TestSound.new
    bgs = sound.play_bgs("Fire", 0)
    assert_instance_of(RPG::BGS, bgs)
    assert(sound.playing_bgs?)
    assert(sound.playing_bgs?(bgs))
    assert(sound.stopping_bgs?.!)
    
    # ボリューム変更
    sound.change_bgs_volume(1)
    assert_equal(1, sound.current_bgs.volume)
    sound.fade_bgs_volume(0)
    assert_equal(1, sound.current_bgs.volume)
    sound.update
    assert_equal(0, sound.current_bgs.volume)

    # 違うファイルを即再生
    bgs = sound.play_bgs_fade(0, "Wind", 0)
    assert(sound.playing_bgs?)
    assert(sound.playing_bgs?(bgs))
    assert(sound.stopping_bgs?.!)

    # 違うファイルをフェードをかけて再生
    bgs = sound.play_bgs_fade(50, "Rain", 0)
    assert(sound.playing_bgs?)
    assert(sound.playing_bgs?(bgs).!)
    assert(sound.stopping_bgs?)
    # 50ms経つまでは停止中のまま
    sound.update
    assert(sound.playing_bgs?)
    assert(sound.playing_bgs?(bgs).!)
    assert(sound.stopping_bgs?)
    sleep(0.1)
    # フェードが終わった
    sound.update
    assert(sound.playing_bgs?)
    assert(sound.playing_bgs?(bgs))
    assert(sound.stopping_bgs?.!)

    # フェードしながら停止
    sound.stop_bgs(50)
    assert(sound.playing_bgs?)
    assert(sound.stopping_bgs?)
    # 50ms経つまでは停止中のまま
    sound.update
    assert(sound.playing_bgs?)
    assert(sound.stopping_bgs?)
    sleep(0.1)
    # フェードが終わった
    sound.update
    assert(sound.playing_bgs?.!)
    assert(sound.stopping_bgs?.!)

    # 再生切り替え中に停止
    sound.play_bgs("Fire", 0)
    assert(sound.playing_bgs?)
    sound.play_bgs("Wind", 0)
    assert_not_nil(sound.instance_eval { @bgs_que })
    assert(sound.stopping_bgs?)
    sound.stop_bgs(1)
    assert(sound.playing_bgs?)
    assert(sound.stopping_bgs?)
    assert_nil(sound.instance_eval { @bgs_que })
    sleep(0.002)
    sound.update
    assert(sound.playing_bgs?.!)
    assert(sound.stopping_bgs?.!)

    # 音量フェード中に停止
    sound.play_bgs("Fire", 0)
    sound.fade_bgs_volume(1)
    sound.stop_bgs(1)
    assert(sound.playing_bgs?)
    assert(sound.stopping_bgs?)
    sleep(0.002)
    sound.update
    assert(sound.playing_bgs?.!)
    assert(sound.stopping_bgs?.!)
    
    # 停止中に再生
    sound.play_bgs("Fire", 0)
    sound.stop_bgs(1)
    assert(sound.playing_bgs?)
    assert(sound.stopping_bgs?)
    sound.play_bgs("Wind", 0)
    assert(sound.playing_bgs?)
    assert(sound.stopping_bgs?)
    sleep(0.1)
    sound.update
    assert(sound.playing_bgs?)
    assert(sound.stopping_bgs?.!)
    
    # 停止中に音量フェード
    sound.stop_bgs(1)
    assert(sound.playing_bgs?)
    assert(sound.stopping_bgs?)
    sound.fade_bgs_volume(1)
    assert(sound.playing_bgs?)
    assert(sound.stopping_bgs?)
    sleep(0.1)
    sound.update
    assert(sound.playing_bgs?.!)
    assert(sound.stopping_bgs?.!)

    # 音量フェード中に再生
    sound.play_bgs("Fire", 0)
    sound.fade_bgs_volume(1)
    bgs = sound.play_bgs_fade(1, "Wind", 0)
    assert(sound.playing_bgs?)
    assert(sound.playing_bgs?(bgs).!)
    assert(sound.stopping_bgs?)
    sleep(0.1)
    sound.update
    assert(sound.playing_bgs?)
    assert(sound.playing_bgs?(bgs))
    assert(sound.stopping_bgs?.!)

    # 音量フェード中に停止
    sound.fade_bgs_volume(1)
    sound.stop_bgs(1)
    assert(sound.playing_bgs?)
    assert(sound.stopping_bgs?)
    sleep(0.1)
    sound.update
    assert(sound.playing_bgs?.!)
    assert(sound.stopping_bgs?.!)
  end

  def test_environment
    sound = TestSound.new
    environment = Itefu::Sound::Environment.new
    environment.bgs_fadeout_duration = 0
    environment.bgs_fade_speed = nil
    environment.listener.attenuation = proc {|vol, x, y| vol * (100 - (x.abs + y.abs)) / 100.0 }
    
    # 音源を移動
    environment.move_listener(100, 200)
    
    # SEを鳴らす
    se = environment.play_se(110, 190, "Decision1", 100)
    assert_equal(80, se.volume)
    sound.stop_se

    # BGSを鳴らす
    bgs_fire = environment.play_bgs(:fire, 120, 190, "Fire", 100)
    assert(environment.playing_bgs_source?.!)
    environment.update
    assert(environment.playing_bgs_source?)
    bgs = Itefu::Sound.current_bgs
    assert_equal(70, bgs.volume)
    assert_equal(bgs_fire, bgs)
    
    # 音の小さいBGSを鳴らす
    bgs_wind = environment.play_bgs(:wind, 110, 195, "Wind", 80)
    environment.update
    bgs = Itefu::Sound.current_bgs
    assert_equal(bgs_fire, bgs)
    
    # 移動した結果, 音量の大きいBGSが入れ替わる
    environment.move_bgs(:wind, 100, 200)
    environment.update
    bgs = Itefu::Sound.current_bgs
    assert_equal(80, bgs.volume)
    assert_equal(bgs_wind, bgs)

    # 通常のBGSが鳴らされる
    Itefu::Sound.play_bgs_fade(0, "Rain")
    assert(environment.playing_bgs_source?.!)
    environment.update
    assert(environment.playing_bgs_source?.!)

    # 通常のBGSが停止される
    Itefu::Sound.stop_bgs
    assert(environment.playing_bgs_source?.!)
    environment.update
    assert(environment.playing_bgs_source?)
    
    environment.finalize
  end


end
