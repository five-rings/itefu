=begin
  Behavior/Node/簡単な動作を定義する
  @note 初期化時に渡したブロックを実行するだけの動作を定義する
=end
class Itefu::BehaviorTree::Node::AdHocAction < Itefu::BehaviorTree::Node::Action
  attr_accessor :block_action

  def on_initialize(&block)
    @block_action = block if block
  end

  def action
    instance_eval(&@block_action) if @block_action
  rescue => e
    show_exception(self.class.to_s, e)
    fail
  end
  
end
