=begin
  BehaviorTree/Node/常に成功を返すノード
=end
class Itefu::BehaviorTree::Node::Succeeder < Itefu::BehaviorTree::Node::Decorator
  
  def on_node_process
    case super
    when Status::RUNNING
      Status::RUNNING
    else
      Status::SUCCESS
    end
  end

end
