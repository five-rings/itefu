=begin
  RGSS3のWindowの拡張
=end
class Itefu::Rgss3::Window < Window
  include Itefu::Rgss3::Resource
  extend Itefu::Rgss3::Resource::Pool::Poolable

  # [Itefu::Rgss3:Bitmap] ウィンドウ作成時に指定されるスキン
  @@default_tone = nil
  
  # [Tone] ウィンドウ作成時に指定されるトーン
  @@default_skin = nil


  # --------------------------------------------------
  # リソース関連

  def contents=(bmp)
    super(Itefu::Rgss3::Resource.swap(self.contents, bmp))
  end
  
  def viewport=(vp)
    super(Itefu::Rgss3::Resource.swap(self.viewport, vp))
  end
  
  def windowskin=(skin)
    super(Itefu::Rgss3::Resource.swap(self.windowskin, skin))
  end
  
  def impl_dispose
    super
    self.viewport = nil
    self.contents = nil
    self.windowskin = nil
  end
  
  def resource_pool_key(x, y, *args)
    args
  end
  
  def reset_resource_properties(x, y, width, height)
    self.visible = false
    # 初期値に戻す
    self.cursor_rect.empty
    self.viewport = nil
    self.active = true
    self.arrows_visible = true
    self.pause = false
    self.x = x
    self.y = y
    self.z = 100
    self.ox = self.oy = 0
    self.padding = 8
    self.back_opacity = 192
    self.contents_opacity = 255
    self.openness = 255
    if @@default_tone
      self.tone.set(@@default_tone) 
    else
      self.tone.set(0, 0, 0, 0)
    end
    self.windowskin = @@default_skin
  end


  # --------------------------------------------------
  # デフォルト設定

  def initialize(x, y, width, height)
    super
    create_contents
    self.windowskin = @@default_skin
    self.tone.set(@@default_tone) if @@default_tone
  end

  def self.default_tone=(tone)
    @@default_tone = tone
  end
  
  def self.default_tone
    @@default_tone
  end

  def self.default_skin=(skin)
    @@default_skin = Itefu::Rgss3::Resource.swap(@@default_skin, skin)
  end
  
  def self.default_skin
    @@default_skin
  end


  # --------------------------------------------------
  # ウィンドウの内容・サイズ関連

  # ウィンドウ内容の作成
  # @param [Fixnum] cw
  # @param [Fixnum] ch
  def create_contents(cw = nil, ch = nil)
    cw ||= contents_width
    ch ||= contents_height
    if cw > 0 && ch > 0
      Itefu::Rgss3::Bitmap.new(cw, ch).auto_release do |bitmap|
        self.contents = bitmap
      end
    else
      # 内容がないのでダミーを与える
      self.contents = Itefu::Rgss3::Bitmap.empty
    end
  end

  # @return [Fixnum] ウィンドウ内容の幅
  # @param [Fixnum] w 指定した場合、現在のサイズでなく w pixelのウィンドウにした場合のサイズを返す
  def contents_width(w = nil)
    (w || self.width) - (self.padding * 2)
  end
  
  # @return [Fixnum] ウィンドウ内容の高さ
  # @param [Fixnum] w 指定した場合、現在のサイズでなく h pixelのウィンドウにした場合のサイズを返す
  def contents_height(h = nil)
    (h || self.height) - (self.padding + self.padding_bottom)
  end
  
  # @return [Fixnum] ウィンドウ左上から、ウィンドウ内容までのオフセット（横）
  def contents_x(x = nil)
    (x || self.x) + self.padding
  end

  # @return [Fixnum] ウィンドウ左上から、ウィンドウ内容までのオフセット（縦)
  def contents_y(y = nil)
    (y || self.y) + self.padding
  end
  
  # @return [Fixnum] 内容の幅に対して必要なウィンドウサイズ
  # @param [Fixnum] cw ウィンドウの内容の幅
  def window_width(cw)
    cw + (self.padding * 2)
  end
  
  # @return [Fixnum] 内容の高さに対して必要なウィンドウサイズ
  # @param [Fixnum] ch ウィンドウの内容の高さ
  def window_height(ch)
    ch + (self.padding + self.padding_bottom)
  end


  # --------------------------------------------------
  # 色関連

  # @return [Color] スキンに設定された保留項目の背景色
  def pending_color
    self.windowskin.get_pixel(80, 80)
  end

  # @return [Color] スキンに設定された文字色
  # @param [Fixnum] n 文字色番号 [0-31]
  def text_color(n)
    self.windowskin.get_pixel(64 + (n % 8) * 8, 96 + (n / 8) * 8)
  end

  # ツクールデフォルト実装で参照している色
  def normal_color;      text_color(0);   end   # @return [Color] 通常
  def system_color;      text_color(16);  end   # @return [Color] システム
  def crisis_color;      text_color(17);  end   # @return [Color] ピンチ
  def knockout_color;    text_color(18);  end   # @return [Color] 戦闘不能
  def gauge_back_color;  text_color(19);  end   # @return [Color] ゲージ背景
  def hp_gauge_color1;   text_color(20);  end   # @return [Color] HP ゲージ 1
  def hp_gauge_color2;   text_color(21);  end   # @return [Color] HP ゲージ 2
  def mp_gauge_color1;   text_color(22);  end   # @return [Color] MP ゲージ 1
  def mp_gauge_color2;   text_color(23);  end   # @return [Color] MP ゲージ 2
  def mp_cost_color;     text_color(23);  end   # @return [Color] 消費 TP
  def power_up_color;    text_color(24);  end   # @return [Color] 装備 パワーアップ
  def power_down_color;  text_color(25);  end   # @return [Color] 装備 パワーダウン
  def tp_gauge_color1;   text_color(28);  end   # @return [Color] TP ゲージ 1
  def tp_gauge_color2;   text_color(29);  end   # @return [Color] TP ゲージ 2
  def tp_cost_color;     text_color(29);  end   # @return [Color] 消費 TP

end
