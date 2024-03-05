=begin
  簡易的な音場
=end
class Itefu::Sound::Environment
  attr_reader :listener                 # [Listener] リスナーのインスタンス
  attr_reader :bgs_sources              # [Array<BgsSource>] 登録されている音源
  attr_accessor :bgs_fadeout_duration   # [Fixnum] BGS切り替え時のフェード時間
  attr_accessor :bgs_fade_speed         # [Fixnum] BGSの音量フェード時の速度

  # リスナー
  # @note 音の聞こえ方を決定するために, 音源からの相対位置と, それに応じた計算方法を持つ
  Listener = Struct.new(:x, :y, :attenuation)

  # 距離減衰の計算方法
  module Attenuator
    module Default
      def self.[](volume, x, y)
        volume * Itefu::Utility::Math.min(1.0, 1000 / ((x/10.0) ** 2 + (y/10.0) ** 2 + 800).to_f)
      end
    end
  end

  # 音源
  class BgsSource < RPG::BGS
    attr_reader :environment
    attr_accessor :id             # [Object] 任意の識別子
    attr_accessor :x, :y          # [Fixnum] 音源の位置
    attr_accessor :attenuation    # [Proc] 音量の計算方法, 音源ごとに計算方法を決定したい場合に指定する (未指定であればListnerのものが使用される)
    
    # @param [Sound::Environment] env
    # @param [Object] id 任意の識別子
    # @param [Fixnum] x 音源の横座標
    # @param [Fixnum] y 音源の縦座標
    # @param [String] name 音源のBGSのラベル
    # @param [Fixnum] volume 再生ボリューム
    # @param [Fixnum] pitch 音高
    def initialize(env, id, x, y, name, volume, pitch)
      @environment = env
      @id = id
      @x = x
      @y = y
      super(name, volume, pitch)
    end

    # @return [Fixnum] リスナーから聞こえる実際の音量
    def actual_volume
      @environment.volume(@volume, @x, @y, @attenuation || @environment.listener.attenuation)
    end
    
    # 音量をリスナーから聞こえる実際の音量に設定する
    def change_volume
      vol = actual_volume
      return if vol == Itefu::Sound.current_bgs.volume
      return if @target_vol == vol
      if @target_vol == 0 && fade_speed = @environment.bgs_fade_speed
        Itefu::Sound.fade_bgs_volume(vol, fade_speed)
      else
        Itefu::Sound.change_bgs_volume(vol)
      end
      @target_vol = vol
    end

    # 再生する    
    def play(pos = 0)
      old = @volume
      if @environment.bgs_fade_speed
        @volume = 0
      else
        @volume = actual_volume
      end
      super
      @target_vol = @volume
      @volume = old
    end
    
    # @return [Boolean] 同じIDのBGSか
    def ==(rhs)
      rhs.is_a?(BgsSource) && self.id == rhs.id
    end
    
    # @return [Boolean] 現在再生中のBGSが同じIDか
    def playing?
      self == Itefu::Sound.current_bgs
    end
  end


  # --------------------------------------------------
  #

  # インスタンス生成時に呼ばれる
  def initialize
    @listener = Listener.new(0, 0, Attenuator::Default)
    @bgs_sources = {}
    @bgs_fade_speed = 1
  end
  
  # インスタンス破棄時に呼ぶ
  def finalize
    clear_bgs
  end

  # 毎フレーム一度呼び出す
  def update
    if playing_bgs_source? || Itefu::Sound.playing_bgs?.!
      # リスナーに影響を受けるBGSを再生中か, 何も再生していないときだけ, BGSを再生する
      if source = @bgs_sources.each_value.max_by(&:actual_volume)
        if source.playing?
          # 今鳴らしているBGSが最大音量なので, 音量を更新する
          source.change_volume
        else
          # 別のBGSが最大音量になったので, BGSを切り替える
          if @bgs_fadeout_duration
            Itefu::Sound.play(source, @bgs_fadeout_duration)
          else
            Itefu::Sound.play(source)
          end
        end
      end
    end
  end
  
  # リスナーの位置を変更する
  # @param [Fixnum] x 移動先の横座標
  # @param [Fixnum] y 移動先の縦座標
  def move_listener(x, y)
    @listener.x = x
    @listener.y = y
  end

  # SEを再生する
  # @param [Fixnum] x SE音源の横座標
  # @param [Fixnum] y SE音源の縦座標
  # @param [String] name 鳴らすSEのラベル
  # @param [Fixnum] volume 再生ボリューム
  # @param [Fixnum] pitch 音高
  # @note コールした瞬間の, リスナーとの相対位置で, 実際の音量が決定される.
  #       再生中にリスナーを移動しても音量は変更されない.
  def play_se(x, y, name, volume = 80, pitch = 100)
    Itefu::Sound.play(RPG::SE.new(name, volume(volume, x, y, @listener.attenuation), pitch))
  end

  # BGSを再生する
  # @param [Object] id 任意の識別子
  # @param [Fixnum] x BGS音源の横座標
  # @param [Fixnum] y BGS音源の縦座標
  # @param [String] name 鳴らすBGSのラベル
  # @param [Fixnum] volume 再生ボリューム
  # @param [Fixnum] pitch 音高
  # @note 複数のBGSを再生した場合, リスナーとの相対位置によって決定される実際の音量が, 一番大きいもののみが再生される.
  #       Environmentの音源でないBGSが再生された場合は、そちらが優先される.(EnvironmentのBGS音源は停止される.)
  #       Environmentの音源でないBGSが停止されると, 登録されているBGS音源のうち一番音量の大きいものが, 自動的に再開される.
  def play_bgs(id, x, y, name, volume = 100, pitch = 100)
    stop_bgs(id)
    @bgs_sources[id] = BgsSource.new(self, id, x, y, name, volume, pitch)
  end

  # BGS音源の位置を移動する
  # @param [Object] id 移動対象のBGS音源の識別子
  # @param [Fixnum] x 移動先の横座標
  # @param [Fixnum] y 移動先の縦座標
  def move_bgs(id, x, y)
    if @bgs_sources.has_key?(id)
      @bgs_sources[id].x = x
      @bgs_sources[id].y = y
    end
  end
  
  # BGS音源を停止する
  # @param [Object] id 停止するBGS音源の識別子
  # @param [Fixnum] duration 停止する際のフェードにかける時間（ミリ秒）
  def stop_bgs(id, duration = 0)
    if @bgs_sources.has_key?(id)
      Itefu::Sound.stop_bgs(duration) if @bgs_sources[id].playing?
      @bgs_sources.delete(id)
    end
  end

  # BGS音源を全て停止する 
  # @param [Fixnum] duration 停止する際のフェードにかける時間（ミリ秒）
  def clear_bgs(duration = 0)
    Itefu::Sound.stop_bgs(duration) if @bgs_sources.each_value.any?(&:playing?)
    @bgs_sources.clear
  end

  # @return [Boolean] EnvironmentのBGS音源を再生しているか
  def playing_bgs_source?
    Itefu::Sound.current_bgs.is_a?(BgsSource)
  end

  # @return [Fixnum] リスナーに聞こえる実際の音量を返す
  # @param [Fixnum] volume 音源から発せられる音量
  # @param [Fixnum] x 音源の横座標
  # @param [Fixnum] y 音源の縦座標
  def volume(volume, x, y, attenuation)
    attenuation[volume, @listener.x - x, @listener.y - y].to_i
  end

end
