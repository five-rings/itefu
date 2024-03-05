=begin
  デザインパターンのStateパターンのStateクラス
=end
module Itefu::Utility::State

  # このステートになったときに呼ばれる
  # @param [Object] context ステート間で共有するデータ
  # @param [Array<Object>] args 任意のパラメータ
  def on_attach(context, *args); end

  # このステートにあるとき毎フレーム呼ばれる更新処理
  # @param [Object] context ステート間で共有するデータ
  # @param [Array<Object>] args 任意のパラメータ
  def on_update(context, *args); end

  # このステートにあるとき毎フレーム呼ばれる描画処理
  # @param [Object] context ステート間で共有するデータ
  # @param [Array<Object>] args 任意のパラメータ
  def on_draw(context, *args); end

  # 別のステートに遷移さいたときに呼ばれる
  # @param [Object] context ステート間で共有するデータ
  def on_detach(context); end

end
