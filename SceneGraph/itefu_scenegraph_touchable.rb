=begin
  SceneGraph/ポインティングデバイスで触ることができるようにする
=end
module Itefu::SceneGraph::Touchable
  def touchable?; shown?; end

  # 触られたときに呼ばれる
  # @note 離されるまでは再度呼ばれない
  # @param [Fixnum] x 接触点(スクリーン座標)
  # @param [Fixnum] y 接触点(スクリーン座標)
  # @param [Object] kind 何でタッチされたかを表す任意の値
  def on_touched(x, y, kind); end
  
  # 触り続けられている間呼ばれる
  # @param [Fixnum] x 接触点(スクリーン座標)
  # @param [Fixnum] y 接触点(スクリーン座標)
  # @param [Object] kind 何でタッチされたかを表す任意の値
  def on_touching(x, y, kind); end

  # 触るのをやめたときに呼ばれる
  # @param [Object] kind 何のタッチが解除されたかを表す任意の値
  def on_untouched(kind); end


  # 触りはじめに一度呼ぶ
  # @param [Fixnum] x 接触点(スクリーン座標)
  # @param [Fixnum] y 接触点(スクリーン座標)
  # @param [Object] kind 何でタッチされたかを表す任意の値
  def touched(x, y, kind = nil)
    on_touched(x, y, kind)
  end
  
  # 触っている間呼び続ける
  # @param [Fixnum] x 接触点(スクリーン座標)
  # @param [Fixnum] y 接触点(スクリーン座標)
  # @param [Object] kind 何でタッチされたかを表す任意の値
  def touching(x, y, kind = nil)
    on_touching(x, y, kind)
  end

  # 触るのを辞めたときに呼ぶ  
  # @param [Object] kind 何のタッチが解除されたかを表す任意の値
  def untouched(kind = nil)
    on_untouched(kind)
  end

end
