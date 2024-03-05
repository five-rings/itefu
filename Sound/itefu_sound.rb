=begin
  サウンド関連
=end
module Itefu::Sound
  DEFAULT_BGM_FADE = 500
  DEFAULT_BGS_FADE = 500

  # 状態変数を初期状態に戻す
  # @note F12などで強制的に中断された場合に使用する
  def self.reset
    reset_me
    reset_bgm
    reset_bgs
  end

  # 毎フレーム更新する処理
  def self.update
    update_me
    update_bgm
    update_bgs
    @environment.update if @environment
  end

  # 音声ファイルを再生する
  # @param [RPG::BGM|RPG::BGS|RPG::SE|RPG::ME] source 鳴らす音声リソース
  # @return [RPG::BGM|RPG::BGS|RPG::SE|RPG::ME] 再生した音声リソースを返す
  def self.play(source, *args)
    case source
    when RPG::BGM;  play_bgm_raw(source, *args)
    when RPG::BGS;  play_bgs_raw(source, *args)
    when RPG::SE;   play_se_raw(source, *args)
    when RPG::ME;   play_me_raw(source, *args)
    end
  end
  
  # @return [Boolean] 音声ファイルを再生しているか
  # @param [RPG::BGM|RPG::BGS] source 確認する音声リソース
  # @note BGM/BGS以外を渡した場合は常にfalseを返す
  def self.playing?(source)
    case source
    when RPG::BGM; playing_bgm?(source)
    when RPG::BGS; playing_bgs?(source)
    else;          false
    end
  end

  # @return [Sound::Environment] 設定されているSound::Environmentを取得する
  def self.environment; @environment; end

  # @param [Sound::Environment] environment Sound::Environmentを設定する
  def self.environment=(environment)
    @environment = environment
  end

  # --------------------------------------------------
  # システムデータ関連のヘルパー
  #
  module SystemData
    # @param [RPG::System] data_system
    def data_system=(data_system)
      @data_system = data_system
    end
  
    # システムBGM
    def play_title_bgm(*args);   play(@data_system.title_bgm, *args);    end   # タイトル画面
    def play_battle_bgm(*args);  play(@data_system.battle_bgm, *args);   end   # 戦闘
    def play_boat_bgm(*args);    play(@data_system.boat.bgm, *args);     end   # 小型船
    def play_ship_bgm(*args);    play(@data_system.ship.bgm, *args);     end   # 大型船
    def play_airship_bgm(*args); play(@data_system.airship.bgm, *args);  end   # 飛行船
  
    # システムME
    def play_battle_end_me;      play(@data_system.battle_end_me);       end   # 戦闘終了
    def play_gameover_me;        play(@data_system.gameover_me);         end   # ゲームオーバー
  
    # システムSE
    def play_cursor_se;          play_system_se(0);                      end   # カーソル移動
    def play_ok_se;              play_system_se(1);                      end   # 決定
    def play_cancel_se;          play_system_se(2);                      end   # キャンセル
    def play_buzzer_se;          play_system_se(3);                      end   # ブザー
    def play_equip_se;           play_system_se(4);                      end   # 装備
    def play_save_se;            play_system_se(5);                      end   # セーブ
    def play_load_se;            play_system_se(6);                      end   # ロード
    def play_battle_start_se;    play_system_se(7);                      end   # 戦闘開始
    def play_escape_se;          play_system_se(8);                      end   # 逃走
    def play_enemy_attack_se;    play_system_se(9);                      end   # 敵の通常攻撃
    def play_enemy_damage_se;    play_system_se(10);                     end   # 敵ダメージ
    def play_enemy_collapse_se;  play_system_se(11);                     end   # 敵消滅
    def play_boss_collapse1_se;  play_system_se(12);                     end   # ボス消滅 1
    def play_boss_collapse2_se;  play_system_se(13);                     end   # ボス消滅 2
    def play_actor_damage_se;    play_system_se(14);                     end   # 味方ダメージ
    def play_actor_collapse_se;  play_system_se(15);                     end   # 味方戦闘不能
    def play_recovery_se;        play_system_se(16);                     end   # 回復
    def play_miss_se;            play_system_se(17);                     end   # ミス
    def play_evasion_se;         play_system_se(18);                     end   # 攻撃回避
    def play_magic_evasion_se;   play_system_se(19);                     end   # 魔法回避
    def play_refrection_se;      play_system_se(20);                     end   # 魔法反射
    def play_shop_se;            play_system_se(21);                     end   # ショップ
    def play_use_item_se;        play_system_se(22);                     end   # アイテム使用
    def play_use_skill_se;       play_system_se(23);                     end   # スキル使用
  
    # システムSEを再生する
    # @param [Fixnum] index SE番号
    def play_system_se(index)
      play(@data_system.sounds[index])
    end
  end
  extend SystemData

  # --------------------------------------------------
  # SE関連の機能
  #
  module SE
    # SEを再生する
    # @param [String] name 鳴らすSEのラベル
    # @param [Fixnum] volume 再生ボリューム
    # @param [Fixnum] pitch 音高
    # @return [RPG::SE] 再生したSEのインスタンス
    def play_se(name, volume = 80, pitch = 100)
      play_se_raw(RPG::SE.new(name, volume, pitch))
    end
    
    # SEを停止する
    def stop_se
      RPG::SE.stop
    end

  private
    # SEを再生する
    # @param [RPG::SE] se 再生するMEのインスタンス
    # @return [RPG::SE] 再生したSEのインスタンス
    def play_se_raw(se)
      se.play
      se
    end
  end
  extend SE

  # --------------------------------------------------
  # ME関連の機能
  #
  module ME
    # MEを再生する
    # @param [String] name 鳴らすMEのラベル
    # @param [Fixnum] volume 再生ボリューム
    # @param [Fixnum] pitch 音高
    # @return [RPG::ME] 再生したMEのインスタンス
    def play_me(name, volume = 100, pitch = 100)
      play_me_raw(RPG::ME.new(name, volume, pitch))
    end
    
    # MEを停止する
    # @param [Fixnum] duration フェードアウトにかける時間
    def stop_me(duration = 0)
      if duration > 0
        RPG::ME.fade(duration)
        timer = Itefu::Timer::Real.new
        @fiber_me = Fiber.new do
          Fiber.yield while timer.elapsed < duration
          # RPG::ME.fadeだけでは停止にならないので時間が経過したら明確に停止する
          RPG::ME.stop
        end
      else
        RPG::ME.stop
        @fiber_me = nil
      end
    end

  private
    # MEの状態変数を初期化する
    def reset_me
      @fiber_me = nil
      RPG::ME.stop
    end

    # 毎フレーム呼ぶ更新処理
    def update_me
      @fiber_me.resume if @fiber_me
    rescue FiberError
      @fiber_me = nil
    end

    # MEを再生する  
    # @param [RPG::ME] me 再生するMEのインスタンス
    # @return [RPG::ME] 再生したMEのインスタンス
    def play_me_raw(me)
      @fiber_me = nil
      me.play
      me
    end
  end
  extend ME

  # --------------------------------------------------
  # BGM関連の機能
  #
  module BGM
    # @return [RPG::BGM] 演奏中のBGM
    def current_bgm
      RPG::BGM.last
    end

    # @return [RPG::BGM] 演奏中または停止後に再生するBGM
    def actual_bgm
      @bgm_que || current_bgm
    end

    # @return [Boolean] BGMを再生しているか
    # @param [RPG::BGM] bgm 再生しているかを確認するBGM
    # @note bgmを省略すると何らかのBGMが再生されているかを返す
    def playing_bgm?(bgm = nil)
      if bgm && @bgm_playing
        current = current_bgm
        current.name == bgm.name && current.pitch == bgm.pitch
      else
        @bgm_playing
      end
    end
    
    # @return [Boolean] BGMを停止中処理中か
    def stopping_bgm?
      @bgm_timer.nil?.!
    end

    # BGMを再生する
    # @note 他のBGMを再生中の場合、フェードアウトしてから新しいBGMを再生する
    #   フェード時間を指定したい場合は (#play_bgm_fade) を使用する
    # @param [String] name 鳴らすBGMのラベル
    # @param [Fixnum] volume 再生ボリューム
    # @param [Fixnum] pitch 音高
    # @return [RPG::BGM] 再生したBGMのインスタンス
    def play_bgm(name, volume = 100, pitch = 100)
      play_bgm_raw(RPG::BGM.new(name, volume, pitch))
    end

    # フェード時間を指定してBGMを再生する
    # @note durationに0を指定すると, 前のBGMや停止中のフェードを無視して, 即時に再生する
    # @param [Fixnum] duration フェード時間（ミリ秒)
    # @param [String] name 鳴らすBGMのラベル
    # @param [Fixnum] volume 再生ボリューム
    # @param [Fixnum] pitch 音高
    # @return [RPG::BGM] 再生したBGMのインスタンス
    def play_bgm_fade(duration, name, volume = 100, pitch = 100)
      play_bgm_raw(RPG::BGM.new(name, volume, pitch), duration)
    end

    # BGMを停止する
    # @param [Fixnum] duration 停止時にかけるフェードの長さ(ミリ秒)
    def stop_bgm(duration = 0)
      @bgm_que = nil
      if duration > 0
        RPG::BGM.fade(duration)
        @bgm_timer = Itefu::Timer::Real.new
        @fiber_bgm = Fiber.new do
          Fiber.yield while @bgm_timer.elapsed < duration
          @bgm_playing = false
          @bgm_timer = nil
          if @bgm_que
            play_bgm_raw(@bgm_que)
            @bgm_que = nil
          end
        end
      else
        RPG::BGM.stop
        @fiber_bgm = @bgm_timer = nil
        @bgm_playing = false
      end
    end

    # BGMの音量を変更する
    # @param [Fixnum] 音量 [0-100]
    def change_bgm_volume(volume)
      if @bgm_que
        # 停止後に再生するBGMがある場合
        @bgm_que.volume = volume
      else
        bgm = current_bgm
        unless bgm.name.empty?
          # posを省略して同じファイルを再生すると音量だけ変えられる
          Audio.bgm_play(Itefu::Rgss3::Filename::Audio::BGM_s % bgm.name, volume, bgm.pitch)
          bgm.volume = volume
        end
      end
    end
    
    # BGMの音量を徐々に変更する
    # @param [Fixnum] volume 最終的な音量 [0-100]
    # @param [Fixnum] speed 1フレームにボリュームをどれだけ変更するか
    def fade_bgm_volume(volume, speed = 1)
      if stopping_bgm?
        @bgm_que.volume = volume if @bgm_que
        return
      end
      current_volume = current_bgm.volume
      return if current_volume == volume
      return change_bgm_volume(volume) if speed <= 0

      @fiber_bgm = Fiber.new do
        step = volume > current_volume ? speed : -speed
        current_volume += step
        while (volume - current_volume) * step > 0
          change_bgm_volume(current_volume)
          Fiber.yield
          current_volume += step
        end
        change_bgm_volume(volume)
      end
    end

  private
    # BGMの状態変数を初期化する
    def reset_bgm
      @bgm_playing = false
      @bgm_timer = nil
      @bgm_que = nil
      @fiber_bgm = nil
      RPG::BGM.stop
    end

    # 毎フレーム呼ぶ更新処理
    def update_bgm
      @fiber_bgm.resume if @fiber_bgm
    rescue FiberError
      @fiber_bgm = nil
    end

    # BGMを再生する
    # @param [RPG::BGM] bgm 再生するBGMのインスタンス
    # @param [Fixnum] duration 再生中に曲を切り替える際のフェード時間(ミリ秒)
    # @return [RPG::BGM] 再生したBGMのインスタンス
    def play_bgm_raw(bgm, duration = DEFAULT_BGM_FADE)
      if duration > 0 && @bgm_playing
        stop_bgm(duration) unless stopping_bgm?
        @bgm_que = bgm
      else
        @bgm_playing = true unless bgm.name.empty?
        @fiber_bgm = @bgm_timer = nil
        # posが設定されている場合は途中から、そうでなければ頭から再生する
        bgm.replay
      end
      bgm
    end
  end
  extend BGM


  # --------------------------------------------------
  # BGS関連の機能
  #
  module BGS
    # @return [RPG::BGS] 演奏中のBGS
    def current_bgs
      RPG::BGS.last
    end

    # @return [RPG::BGS] 演奏中または停止後に再生するBGS
    def actual_bgs
      @bgs_que || current_bgs
    end

    # @return [Boolean] BGSを再生しているか
    # @param [RPG::BGS] bgs 再生しているかを確認するBGS
    # @note bgsを省略すると何らかのBGSが再生されているかを返す
    def playing_bgs?(bgs = nil)
      if bgs && @bgs_playing
        current = current_bgs
        current.name == bgs.name && current.pitch == bgs.pitch
      else
        @bgs_playing
      end
    end
    
    # @return [Boolean] BGSを停止中処理中か
    def stopping_bgs?
      @bgs_timer.nil?.!
    end

    # BGSを再生する
    # @note 他のBGSを再生中の場合、フェードアウトしてから新しいBGSを再生する
    #   フェード時間を指定したい場合は (#play_bgs_fade) を使用する
    # @param [String] name 鳴らすBGSのラベル
    # @param [Fixnum] volume 再生ボリューム
    # @param [Fixnum] pitch 音高
    # @return [RPG::BGS] 再生したBGSのインスタンス
    def play_bgs(name, volume = 100, pitch = 100)
      play_bgs_raw(RPG::BGS.new(name, volume, pitch))
    end

    # フェード時間を指定してBGSを再生する
    # @note durationに0を指定すると, 前のBGSや停止中のフェードを無視して, 即時に再生する
    # @param [Fixnum] duration フェード時間（ミリ秒)
    # @param [String] name 鳴らすBGSのラベル
    # @param [Fixnum] volume 再生ボリューム
    # @param [Fixnum] pitch 音高
    # @return [RPG::BGS] 再生したBGSのインスタンス
    def play_bgs_fade(duration, name, volume = 100, pitch = 100)
      play_bgs_raw(RPG::BGS.new(name, volume, pitch), duration)
    end

    # BGSを停止する
    # @param [Fixnum] duration 停止時にかけるフェードの長さ(ミリ秒)
    def stop_bgs(duration = 0)
      @bgs_que = nil
      if duration > 0
        RPG::BGS.fade(duration)
        @bgs_timer = Itefu::Timer::Real.new
        @fiber_bgs = Fiber.new do
          Fiber.yield while @bgs_timer.elapsed < duration
          @bgs_playing = false
          @bgs_timer = nil
          if @bgs_que
            play_bgs_raw(@bgs_que)
            @bgs_que = nil
          end
        end
      else
        RPG::BGS.stop
        @fiber_bgs = @bgs_timer = nil
        @bgs_playing = false
      end
    end

    # BGSの音量を変更する
    # @param [Fixnum] 音量 [0-100]
    def change_bgs_volume(volume)
      if @bgs_que
        # 停止後に再生するBGSがある場合
        @bgs_que.volume = volume
      else
        bgs = current_bgs
        unless bgs.name.empty?
          # posを省略して同じファイルを再生すると音量だけ変えられる
          Audio.bgs_play(Itefu::Rgss3::Filename::Audio::BGS_s % bgs.name, volume, bgs.pitch)
          bgs.volume = volume
        end
      end
    end
    
    # BGSの音量を徐々に変更する
    # @param [Fixnum] volume 最終的な音量 [0-100]
    # @param [Fixnum] speed 1フレームにボリュームをどれだけ変更するか
    def fade_bgs_volume(volume, speed = 1)
      if stopping_bgs?
        @bgs_que.volume = volume if @bgs_que
        return
      end
      current_volume = current_bgs.volume
      return if current_volume == volume
      return change_bgs_volume(volume) if speed <= 0

      @fiber_bgs = Fiber.new do
        step = volume > current_volume ? speed : -speed
        current_volume += step
        while (volume - current_volume) * step > 0
          change_bgs_volume(current_volume)
          Fiber.yield
          current_volume += step
        end
        change_bgs_volume(volume)
      end
    end

  private
    # BGSの状態変数を初期化する
    def reset_bgs
      @bgs_playing = false
      @bgs_timer = nil
      @bgs_que = nil
      @fiber_bgs = nil
      RPG::BGS.stop
    end

    # 毎フレーム呼ぶ更新処理
    def update_bgs
      @fiber_bgs.resume if @fiber_bgs
    rescue FiberError
      @fiber_bgs = nil
    end

    # BGSを再生する
    # @param [RPG::BGS] bgs 再生するBGSのインスタンス
    # @param [Fixnum] duration 再生中に曲を切り替える際のフェード時間(ミリ秒)
    # @return [RPG::BGS] 再生したBGSのインスタンス
    def play_bgs_raw(bgs, duration = DEFAULT_BGS_FADE)
      if duration > 0 && @bgs_playing
        stop_bgs(duration) unless stopping_bgs?
        @bgs_que = bgs
      else
        @bgs_playing = true unless bgs.name.empty?
        @fiber_bgs = @bgs_timer = nil
        # posが設定されている場合は途中から、そうでなければ頭から再生する
        bgs.replay
      end
      bgs
    end
  end
  extend BGS

end
