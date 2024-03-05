=begin
  BehaviorTree/Node/子ノードを順次実行し、失敗したノードがあれば中断する
  @note 子ノードに対して and をとる
=end
class Itefu::BehaviorTree::Node::Sequence < Itefu::BehaviorTree::Node::Composite

  def on_child_node_processed(child_status)
    case child_status
    when Status::SUCCESS
      # 子ノードが成功するうちは次のノードへ
      Status::RUNNING
    else
      child_status
    end
  end
  
  def status_when_completes
    # 子ノードがすべて成功した
    Status::SUCCESS
  end

end
