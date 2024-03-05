=begin
  BehaviorTree/Node/このツリーを持つAIの具体的な動作の共通クラス
=end
class Itefu::BehaviorTree::Node::Action < Itefu::BehaviorTree::Node::Leaf

  # 動作
  def action
    # 派生先で実装する
    raise Exception::NotImplemented;
  end

  # 処理の内容を一時中断し残りを次のフレームにまわす
  # @note actionの中から呼ぶこと  
  def suspend
    Fiber.yield Status::RUNNING
  end
  
  # 処理を成功扱いで終了する
  # @note actionの中から呼ぶこと  
  def succeed
    Fiber.yield Status::SUCCESS
  end
  
  # 処理を失敗扱いで終了する
  # @note actionの中から呼ぶこと  
  def fail
    Fiber.yield Status::FAILURE
  end
  
  def node_init
    @fiber = Fiber.new {
      action
      @fiber = nil
      succeed
    }
    super
  end

  def on_node_process
    if @fiber
      @fiber.resume
    else
      Status::SUCCESS
    end
  end  

end
