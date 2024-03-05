=begin
  ツクールの「アニメーション」で作成できるエフェクトアニメーション
=end
class Itefu::Animation::Effect < Itefu::Animation::Base
  include Itefu::Resource::Loader
  attr_reader :muted                    # [Boolean] trueを指定するとSEを鳴らさなくする
  attr_reader :blinded                  # [Boolean] trueを指定するとflashを無効化する
  attr_reader :offset_x, :offset_y      # [Fixnum] 表示位置をずらす
  attr_reader :offset_z                 # [Fixnum] 前後位置を調整する
  attr_accessor :sound_env              # [Itefu::Sound::Environment] 指定されていればSEを鳴らす際に距離減衰を考慮する
  attr_accessor :called_empty_timing    # [Proc] 空のタイミングを実行した際に呼ばれる

  # SEを鳴らすかどうかを設定する
  # @param [Boolean] value 音を鳴らすかどうか
  # @return [Animation::Effect] レシーバー自身を返す
  def mute(value)
    @muted = value
    self
  end

  # 画面フラッシュを行うかどうかを設定する
  # @param [Boolean] value 画面フラッシュするかどうか
  # @return [Animation::Effect] レシーバー自身を返す
  def blind(value)
    @blinded = value
    self
  end

  # 表示位置をずらす
  # @param [Fixnum|NilClass] x 横方向にずらす量
  # @param [Fixnum|NilClass] y 縦方向にずらす量
  # @return [Animation::Effect] レシーバー自身を返す
  def offset(x, y)
    @offset_x = x if x
    @offset_y = y if y
    self
  end

  # 前後位置をずらす
  # @param [Fixnum|NilClass] z Z調整値
  # @return [Animation::Effect] レシーバー自身を返す
  # @note 未指定またはnilの場合は0扱い
  def offset_z(z)
    @offset_z = z
    self
  end

  # 表示倍率を変更する
  # @return [Animation::Effect] レシーバー自身を返す
  def zoom(x, y)
    @zoom_x = x if x
    @zoom_y = y if y
    self
  end

  # @param [RPG::Animation] rpg_anime 再生するアニメーション
  # @note rpg_animeを生成時に指定しない場合必ずstart時に指定する
  def on_initialize(rpg_anime = nil)
    @rpg_anime = rpg_anime
    @sprites = []
    if rpg_anime
      create_sprites
      load_bitmaps
    end
  end

  # インスタンス破棄時の処理
  def on_finalize
    release_all_resources
    @id1 = @id2 = @bitmap1 = @bitmap2 = nil
    @target = Itefu::Rgss3::Resource.swap(@target, nil)
    clear_targets
    @viewport = Itefu::Rgss3::Resource.swap(@viewport, nil)
    @sprites.each(&:dispose)
    @sprites.clear
    @rpg_anime = nil
  end

  # 追加した対象を消去する
  def clear_targets
    if @targets
      @targets.each(&:ref_detach)
      @targets.clear
    end
  end
  
  # @param [Animation::Player] player プレイヤーのインスタンス
  # @param [RPG::Animation] rpg_anime 再生するアニメーション
  # @note rpg_animeを省略する場合、前回指定したものが使用される
  def on_start(player, rpg_anime = nil)
    if rpg_anime
      @rpg_anime = rpg_anime
      create_sprites
      load_bitmaps
    end
    setup_initial_position

    @player = player
    @prev_frame_count = -1
  end

  # 再生終了時の処理
  def on_finish
    @player = nil
    @sprites.each {|sprite|
      sprite.visible = false unless sprite.disposed?
    }
  end

  # 再生処理
  def on_update(delta)
    # RPG::Animation内部でのフレーム数
    frame_count = @play_count.to_i / Itefu::Rgss3::Definition::Animation::System::FRAME_RATE

    if frame_count >= @rpg_anime.frame_max
      # 再生終了
      finish

    elsif frame_count != @prev_frame_count
      # セルを更新する
      update_cells(@rpg_anime.frames[frame_count])

      # タイミングを処理する
      @rpg_anime.timings.each do |timing|
        trigger_timing(timing) if timing.frame == frame_count
      end
    end

    @prev_frame_count = frame_count
  end

  # エフェクトを表示する対象のSpriteを指定する
  # @param [Itefu::Rgss3::Sprite|Array] target エフェクトを表示する対象
  # @param [Itefu::Rgss3::Viewport] エフェクトを表示するViewport
  # @return [Animation::Effect] レシーバー自身を返す
  def assign_target(target, viewport = nil)
    if Array === target
      # 複数指定の場合先頭のassign用とみなす
      clear_targets
      add_target(target)
      target = @targets.shift
      target.ref_detach
    end
    @target = Itefu::Rgss3::Resource.swap(@target, target)
    @viewport = Itefu::Rgss3::Resource.swap(@viewport, viewport)
    @sprites.each {|sprite| sprite.viewport = viewport }
    @x = @y = nil
    self
  end

  # フラッシュなどの効果を適用する対象を追加する
  # @param [Array|Itefu::Rgss3::Sprite] targets
  # @note assign_target/assign_positionを指定した上で更に追加したいものをこれで指定する
  def add_target(targets)
    @targets ||= []
    if Array === targets
      targets.each(&:ref_attach)
      @targets.concat targets
    else
      targets.ref_attach
      @targets << targets
    end
  end

  # エフェクトを表示する座標を指定する
  # @param [Fixnum] x 横座標
  # @param [Fixnum] y 縦座標
  # @param [Itefu::Rgss3::Viewport] エフェクトを表示するViewport
  # @return [Animation::Effect] レシーバー自身を返す
  def assign_position(x, y, viewport = nil)
    @x = x
    @y = y
    @viewport = Itefu::Rgss3::Resource.swap(@viewport, viewport)
    @sprites.each {|sprite| sprite.viewport = viewport }
    @target = Itefu::Rgss3::Resource.swap(@target, nil)
    self
  end

private
  # このアニメで使用するセル数 = Sprite数
  def max_cell
    @rpg_anime && @rpg_anime.frames.max_by {|frame|
      frame.cell_max
    }.cell_max || Itefu::Rgss3::Definition::Animation::System::CELL_MAX
  end

  # 内部で使用するSpriteを生成する
  def create_sprites
    diff = max_cell - @sprites.size
    if diff > 0
      @sprites.concat diff.times.map {
        Itefu::Rgss3::Sprite.new(@viewport)
      }
    end
  end
  
  # エフェクトに使用するファイル名を取得する
  def filename(signature)
    Itefu::Rgss3::Filename::Graphics::ANIMATIONS_s % signature
  end

  # エフェクトに使用するBitmapファイルを読み込む
  # @note 以前読み込んでいたものは自動的に破棄される
  def load_bitmaps
    id1 = @rpg_anime.animation1_name.empty? ? nil : load_bitmap_resource(filename(@rpg_anime.animation1_name), @rpg_anime.animation1_hue)
    @bitmap1 = resource_data(id1)
    release_resource(@id1) if @id1
    @id1 = id1

    id2 = @rpg_anime.animation2_name.empty? ? nil : load_bitmap_resource(filename(@rpg_anime.animation2_name), @rpg_anime.animation2_hue)
    @bitmap2 = resource_data(id2)
    release_resource(@id2) if @id2
    @id1 = id2
  end

  # 初期位置を設定する
  # @note これを呼ぶ前に, rpg_animeが設定され, assign_targetかassign_positionが設定されている必要がある
  def setup_initial_position
    @base_x = @x
    @base_y = @y
    target = @target

    case @rpg_anime.position
    when Itefu::Rgss3::Definition::Animation::Position::TOP
      if target
        @base_x ||= target.x - target.ox + target.width / 2
        @base_y ||= target.y - target.oy
      end
    when Itefu::Rgss3::Definition::Animation::Position::CENTER
      if target
        @base_x ||= target.x - target.ox + target.width / 2
        @base_y ||= target.y - target.oy + target.height / 2
      end
    when Itefu::Rgss3::Definition::Animation::Position::BOTTOM
      if target
        @base_x ||= target.x - target.ox + target.width / 2
        @base_y ||= target.y - target.oy + target.height
      end
    when Itefu::Rgss3::Definition::Animation::Position::SCREEN
      if @viewport
        @base_x ||= @viewport.rect.width / 2
        @base_y ||= @viewport.rect.height / 2
      else
        @base_x ||= Graphics.width / 2
        @base_y ||= Graphics.height
      end
    end

    unless @base_x && @base_y
      raise FailedToStartException
    end

    @base_x += (@offset_x || 0)
    @base_y += (@offset_y || 0)
  end

  # セルの表示を更新する
  # @param [RPG::Animation::Frame] frame_data このフレームでのセルの情報
  def update_cells(frame_data)
    cell_data = frame_data.cell_data
    z = @offset_z || 0

    @sprites.each.with_index do |sprite, i|
      pattern = Itefu::Rgss3::Definition::Animation::CellData.pattern(cell_data, i)
      if Itefu::Rgss3::Definition::Animation::Pattern.valid?(pattern)
        sprite.visible = true
      else
        sprite.visible = false
        next
      end

      sprite.bitmap = Itefu::Rgss3::Definition::Animation::Pattern.uses_bitmap1?(pattern) ? @bitmap1 : @bitmap2
      sprite.src_rect.set(
        Itefu::Rgss3::Definition::Animation::Pattern.to_x(pattern) * Itefu::Rgss3::Definition::Animation::System::CELL_SIZE,
        Itefu::Rgss3::Definition::Animation::Pattern.to_y(pattern) * Itefu::Rgss3::Definition::Animation::System::CELL_SIZE,
        Itefu::Rgss3::Definition::Animation::System::CELL_SIZE,
        Itefu::Rgss3::Definition::Animation::System::CELL_SIZE
      )
      sprite.x = Itefu::Rgss3::Definition::Animation::CellData.x(cell_data, i)
      sprite.y = Itefu::Rgss3::Definition::Animation::CellData.y(cell_data, i)
      sprite.x *= @zoom_x if @zoom_x
      sprite.y *= @zoom_y if @zoom_y
      sprite.x += @base_x
      sprite.y += @base_y
      sprite.z = i + z
      sprite.ox = sprite.oy = Itefu::Rgss3::Definition::Animation::System::CELL_SIZE / 2
      sprite.zoom_x = sprite.zoom_y = Itefu::Rgss3::Definition::Animation::CellData.zoom(cell_data, i)
      sprite.zoom_x *= @zoom_x if @zoom_x
      sprite.zoom_y *= @zoom_y if @zoom_y

      sprite.angle = (360 - Itefu::Rgss3::Definition::Animation::CellData.rotation(cell_data, i))
      sprite.mirror = Itefu::Rgss3::Definition::Animation::CellData.mirrored?(cell_data, i)
      sprite.opacity = Itefu::Rgss3::Definition::Animation::CellData.opacity(cell_data, i)
      sprite.blend_type = Itefu::Rgss3::Definition::Animation::CellData.blend_type(cell_data, i)
    end
  end
  
  # タイミングデータを処理する
  # @note タイミングとはエフェクトの再生に合わせて呼び出すワンショットの効果のこと
  # @param [RPG::Animation::Timing] timing タイミングデータ
  def trigger_timing(timing)
    unless timing.se.name.empty? || @muted
      if @sound_env
        @sound_env.play_se(@base_x, @base_y, timing.se.name, timing.se.volume, timing.se.pitch)
      else
        Itefu::Sound.play(timing.se)
      end
    end

    case timing.flash_scope
    when Itefu::Rgss3::Definition::Animation::FlashScope::NONE
      # 演出とあわせた処理ができるよう、フラッシュもSEも指定されていないタイミングに合わせてコールバックを呼ぶ
      @called_empty_timing.call(self) if @called_empty_timing && timing.se.name.empty?
    when Itefu::Rgss3::Definition::Animation::FlashScope::TARGET
      @target.flash(timing.flash_color, timing.flash_duration * duration_scale) if @target
      @targets.each do |target|
        target.flash(timing.flash_color, timing.flash_duration * duration_scale)
      end if @targets
    when Itefu::Rgss3::Definition::Animation::FlashScope::SCREEN
      @viewport.flash(timing.flash_color, timing.flash_duration * duration_scale) if @viewport
    when Itefu::Rgss3::Definition::Animation::FlashScope::ERASE_TARGET
      @target.flash(nil, timing.flash_duration * duration_scale) if @target
      @targets.each do |target|
        target.flash(nil, timing.flash_duration * duration_scale)
      end if @targets
    end unless @blinded
  end
  
  # @return [Numeric] フラッシュの時間を何倍にするか
  # @note 再生倍数の逆数をかけることで, 低速再生のときのフラッシュを長く, 高速最盛時のフラッシュを短くする
  def duration_scale
    if @player
      Itefu::Rgss3::Definition::Animation::System::FRAME_RATE / (@player.animation_speed * play_speed)
    else
      Itefu::Rgss3::Definition::Animation::System::FRAME_RATE / play_speed
    end
  end

end
