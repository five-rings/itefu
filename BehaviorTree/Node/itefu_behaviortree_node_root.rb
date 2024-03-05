=begin
  BehaviorTree/Node/ルートノード
=end
class Itefu::BehaviorTree::Node::Root < Itefu::BehaviorTree::Node::Decorator

  # @return [Boolean] 子のノードが生存しているか
  def alive?; @context[:alive]; end

  # このノードが不要になった場合に呼ぶ
  def die; @context[:alive] = false; end

  def create_context(context)
    @context = context || {}
    @context[:alive] = true
    @context
  end

  def update
    node_reset
    node_process
  end

  # @param [Object] resuming_context このオブジェクトにステータスを保存する
  # @note resuming_contextには def []= が実装されていること
  # @return [Object] resuming_contextを返す
  def save_status(resuming_context = {})
    super(resuming_context, "/")
    resuming_context
  end

  # @param [Object] resuming_context このオブジェクトからステータスを復元する
  # @note resuming_contextには def [] が実装されていること
  # @return [Object] resuming_contextを返す
  def load_status(resuming_context)
    super(resuming_context, "/") if resuming_context
    resuming_context
  end

end
