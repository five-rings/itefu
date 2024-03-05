=begin
  パフォーマンス計測用のカウンタを提供し、その計測結果を表示する
=end
class Itefu::Debug::Performance::Manager < Itefu::System::Base
  include Itefu::Resource::Container
  WIDTH = 120         # 表示サイズ（横幅）
  HEIGHT = 60         # 表示サイズ（縦幅）
  PADDING = 10        # 画面端からの距離
  BUFFER_SIZE = 2     # 内部で使用するSpriteの数

  COLOR_BACKGROUND = Itefu::Color.Black # 背景色
  COLOR_BACKGROUND_ALPHA = 0x7f         # 背景の透明度
  COLOR_BAR = Itefu::Color.White        # 基準線の色

  Counter = Struct.new(:color, :instance)

  # @return [Boolean] 表示されているか
  def active?
    @viewport && @viewport.visible
  end

  # 表示する
  def activate
    @viewport.visible = true
  end
  
  # 非表示にする
  def deactivate
    @viewport.visible = false
  end
  
  # 表示・非表示を切り替える
  def toggle_active
    if active?
      deactivate
    else
      activate
    end
  end
  
  # @return [Counter] 計測用カウンタのインスタンス
  # @param [Symbol] id 識別子
  def counter(id)
    @counters[id].instance
  end
  
  # 計測用カウンタを追加する
  # @param [Symbol] id 識別子
  # @param [Color] color 表示色
  def add_counter(id, color)
    @counters[id] = Counter.new(color, Itefu::Debug::Performance::Counter.new)
  end

private
  def on_initialize(z, rect = nil)
    @counters = {}
    @frame_counter = 0

    @viewport = create_resource(Itefu::Rgss3::Viewport, rect || Itefu::Rgss3::Rect::TEMP.set(Graphics.width-WIDTH-PADDING, PADDING, WIDTH, HEIGHT))
    @viewport.visible = true
    @viewport.z = z

    @scene_graph = create_resource(Itefu::SceneGraph::Root)
    
    #　処理落ちの基準線を表示するためのSprite
    mpf = Itefu::Utility::Time.frame_to_millisecond(1)
    bitmap = create_resource(Itefu::Rgss3::Bitmap, WIDTH, HEIGHT)
    bitmap.fill_rect_alpha(COLOR_BACKGROUND_ALPHA, 0, 0, WIDTH, HEIGHT, COLOR_BACKGROUND)
    bitmap.fill_rect(0, HEIGHT-mpf, WIDTH, 1, COLOR_BAR)
    @scene_graph.add_sprite(WIDTH, HEIGHT, bitmap).sprite.viewport = @viewport

    # 処理グラフ表示用のSprite
    @sprites = BUFFER_SIZE.times.map {|i|
      @scene_graph.add_sprite(WIDTH, HEIGHT).tap {|node|
        node.sprite.viewport = @viewport
      }.transfer(WIDTH * i, nil)
    }
  end
  
  def on_finalize
    finalize_all_resources
  end
  
  def on_update
    return unless active?

    # 計測した値を描画する
    draw_counter(@frame_counter)

    # SceneGraphの更新
    @scene_graph.update
    @scene_graph.update_interaction
    @scene_graph.update_actualization
    @scene_graph.draw

    # 次のフレームの準備
    @frame_counter += 1
    if @frame_counter >= WIDTH
      @sprites.each {|sprite|
        sprite.move(-1, 0)
        sprite.transfer(WIDTH * (BUFFER_SIZE-1), nil) if sprite.pos_x <= -WIDTH
      }
    end
  end

  # 計測した値を描画する
  def draw_counter(frame_count)
    index = frame_count / WIDTH % BUFFER_SIZE
    pos = frame_count % WIDTH
    bitmap = @sprites[index].sprite.bitmap
    bitmap.clear_rect(pos, 0, 1, HEIGHT)
    t = @counters.each_value.inject(0) do |memo, counter|
      elapsed = counter.instance.elapsed
      bitmap.fill_rect(pos, HEIGHT-memo-elapsed, 1, elapsed, counter.color)
      memo + elapsed
    end
  end
  
end
