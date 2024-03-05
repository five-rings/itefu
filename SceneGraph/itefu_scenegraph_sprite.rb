=begin
  Spriteを使って描画を行うSceneGraphのノード
=end
class Itefu::SceneGraph::Sprite < Itefu::SceneGraph::Base
  include Itefu::SceneGraph::RenderTarget
  attr_reader :anchor_x, :anchor_y    # [Numeric] 回転の中心になるアンカーポイント, 小数だとサイズの割合になる
  attr_reader :offset_x, :offset_y    # [Fixnum] 描画位置のオフセット, Spriteの前後関係はzが同じだとyで計算されるので, 前後関係を維持したい場合に使用する
  attr_reader :sprite                 # [Itefu::Rgss3::Sprite] Sprite本体
  
  def buffer; @to_create_buffer && @sprite.bitmap; end
  def viewport; @sprite.viewport; end

  # @param [SceneGraph::Base] parent 親ノード
  # @param [Fixnum] w 横幅
  # @param [Fixnum] h 高さ
  # @param [Itefu::Rgss3::Bitmap] buffer 既に生成済みのBitmapを表示したい場合に指定する
  # @param [Fixnum] u バッファ表示位置の横座標, noteを参照
  # @param [Fixnum] v バッファ表示位置の縦座標, noteを参照
  # @note u,vを指定するとbufferの(u,v)からsize_wh分だけを表示する
  def initialize(parent, w, h, buffer = nil, u = nil, v = nil)
    super(parent)
    @sprite = Itefu::Rgss3::Sprite.new
    if buffer
      @sprite.bitmap = buffer
      @sprite.src_rect.set(u || 0, v || 0, w, h)
    else
      @to_create_buffer  = true if @to_create_buffer.nil?
    end
    @anchor_x = @anchor_y = 0
    @offset_x = @offset_y = 0
    resize(w, h)
  end
  
  # 生成済みのSpriteを同じ内容で生成しなおす
  # @note Spriteの生成順が表示のソート順に影響するので無理矢理表示順を変えたいときに使うことを想定している
  def recreate_sprite
    @sprite.clone.auto_release {|new_sprite|
      @sprite = @sprite.swap(new_sprite)
    } if @sprite
  end

  def reassign_bitmap(bitmap, w = nil, h = nil, u = nil, v = nil)
    if @sprite && @to_create_buffer.!
      @sprite.bitmap = bitmap
      w ||= size_w
      h ||= size_h
      @sprite.src_rect.set(u || 0, v || 0, w, h)
      resize(w, h)
    end 
  end
  
  # アンカーポイントを設定する
  # @param [Numeric] アンカーの横位置
  # @param [Numeric] アンカーの縦位置
  # @return [self] レシーバー自身を返す
  # @note Spriteを回転する際にアンカーポイントが中心点になる,
  #       整数を指定するとその値が, それ以外（小数など）を指定すると Size * Anchorを計算した値が設定される.
  def anchor(x, y)
    @anchor_x = x if x
    @anchor_y = y if y
    self
  end
  
  # 表示位置を調整する
  # @param [Numeric] x 横の調整量
  # @param [Numeric] y 縦の調整量
  # @return [self] レシーバー自身を返す
  def offset(x, y)
    @offset_x = x if x
    @offset_y = y if y
    self
  end
  
  # アニメーション用のアクセッサ
  def offset_x=(x)
    # offset(x, nil)
    @offset_x = x
    x
  end
  
  # アニメーション用のアクセッサ
  def offset_y=(y)
    # offset(nil, y)
    @offset_y = y
    y
  end
  
  # @return [Fixnum] このノードからの相対位置を返す
  # @param [SceneGraph::Base] node 相対位置を計算する対象
  # @note drawの中など, 相対位置を計算済みの状況でのみ正しい値を返す
  def relative_pos_x(node)
    node.screen_x - screen_x
  end
  
  # @return [Fixnum] このノードからの相対位置を返す
  # @param [SceneGraph::Base] node 相対位置を計算する対象
  # @note drawの中など, 相対位置を計算済みの状況でのみ正しい値を返す
  def relative_pos_y(node)
    node.screen_y - screen_y
  end
  
  # 描画潤ソート用の値を返す
  def comparison_value(index)
    @comp_value ||= [0] * 4
    @comp_value[0] = viewport && viewport.z || -1
    @comp_value[1] = @sprite.z
    @comp_value[2] = @sprite.y
    @comp_value[3] = -index
    @comp_value
  end

private
  def impl_finalize
    super
    @sprite = @sprite.swap(nil)
  end

  def impl_resize(w, h)
    super
    if @to_create_buffer
      # 自前で作成したバッファを作り直す
      Itefu::Rgss3::Bitmap.new(w, h).auto_release {|bitmap|
        @sprite.bitmap = bitmap
      }
      be_corrupted
    end
    @sprite.src_rect.width = w
    @sprite.src_rect.height = h
  end

  def impl_update_actualization
    actualize_screen_pos
    actualize_visibility
    # ノードの値をSpriteに設定する
    actualize_oxy
    actualize_sprite_pos
    actualize_sprite_visible
    # Spriteが自身を操作する場合を考慮して, Spriteの値を決定した後にUpdateを呼ぶ
    @sprite.update
    @children.keep_if(&:update_actualization)
    @ids.keep_if {|k,v| v.alive? } if @ids
  end
  
  # アンカーポイントをSpriteに設定する
  def actualize_oxy
    @sprite.ox = value_to_actual(anchor_x, size_w)
    @sprite.oy = value_to_actual(anchor_y, size_h)
  end
  
  # 座標をSpriteに設定する
  def actualize_sprite_pos
    @sprite.x = @screen_x + @sprite.ox + value_to_actual(@offset_x, size_w)
    @sprite.y = @screen_y + @sprite.oy + value_to_actual(@offset_y, size_h)
  end
  
  # 描画設定をSpriteに設定する
  def actualize_sprite_visible
    @sprite.visible = shown?
  end

  # アンカーポイントを整数にして返す  
  def value_to_actual(value, range)
    case value
    when Integer
      value
    else
      (value * range).to_i
    end
  end

end
