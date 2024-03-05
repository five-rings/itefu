=begin
  BehaviorTree/Node/失敗になるまで子を繰り返し実行するノード
=end
class Itefu::BehaviorTree::Node::UntilFail < Itefu::BehaviorTree::Node::Decorator
  
  def on_node_process
    case super
    when Status::FAILURE
      Status::SUCCESS
    else
      Status::RUNNING
    end
  end

end
