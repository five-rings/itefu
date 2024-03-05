=begin
  コールバックメソッドの追加と呼び出しを行うヘルパ  
=end
module Itefu::Utility::Callback

  # コールバックを呼び出す
  # @param [Symbol] id 識別子
  # @param [Array] args コールバックを呼び出す際に渡す任意の引数
  # @note selfは自動でコールバックの第一実引数として渡される
  def execute_callback(id, *args)
    @callbacks[id].each do |cb|
      cb.call(self, *args)
    end if has_callback?(id)
  end

  # コールバックを登録する
  # @param [Symbol] id 識別子
  # @param [Object] cb 登録するコールバック(引数渡し)
  # @param [Object] block 登録するコールバック(ブロック渡し)
  # @return [Array] idに登録されているコールバックの配列
  def add_callback(id, cb = nil, &block)
    @callbacks ||= {}
    @callbacks[id] ||= []
    @callbacks[id] << cb if cb
    @callbacks[id] << block if block
    @callbacks[id]
  end
  
  # コールバックを削除する
  # @param [Symbol] id 削除対象の識別子
  # @param [Object] cb 削除するコールバック
  # @return [Object] 削除したコールバック
  def remove_callback(id, cb)
    @callbacks[id].delete(cb) if has_callback?(id)
  end
  
  # コールバックを全削除する
  # @param [Symbol] id 削除対象の識別子, 未指定で全IDを対象に削除する
  def clear_callbacks(id = nil)
    return unless @callbacks
    if id
      @callbacks[id].clear if @callbacks.has_key?(id)
    else
      @callbacks.clear
    end
  end
  
  # @return [Boolean] コールバックが登録されているか
  # @param [Symbol] id 削除対象の識別子
  def has_callback?(id)
    @callbacks && @callbacks.has_key?(id) && @callbacks[id].empty?.!
  end
  
  # @return [Array|NilClass] コールバック一覧
  # @param [Symbol] id 識別子
  def callbacks(id)
    @callbacks && @callbacks[id]
  end

end