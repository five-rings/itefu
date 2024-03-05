=begin
  BehaviorTree/Node/子ノードを順次実行し、成功したノードがあった時点で中断する
  @note 子ノードに対して or をとる
=end
class Itefu::BehaviorTree::Node::Selector < Itefu::BehaviorTree::Node::Composite

  def on_child_node_processed(child_status)
    case child_status
    when Status::FAILURE
      # 子ノードがまだ成功しないので次のノードへ
      Status::RUNNING
    else
      child_status
    end
  end
  
  def status_when_completes
    # 子ノードがいずれも成功しなかった
    Status::FAILURE
  end

end
