=begin
  BehaviorTree/Node/成否を反転させるノード
=end
class Itefu::BehaviorTree::Node::Inverter < Itefu::BehaviorTree::Node::Decorator
  
  def on_node_process
    returned_status = super
    case returned_status
    when Status::SUCCESS
      Status::FAILURE
    when Status::FAILURE
      Status::SUCCESS
    else
      returned_status
    end
  end

end
