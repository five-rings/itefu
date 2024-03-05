=begin
  BehaviorTree/Node/子を接続しない末端のノードの共通クラス
=end
class Itefu::BehaviorTree::Node::Leaf < Itefu::BehaviorTree::Node::Base

  def save_status(resuming_context, path)
    if running?
      resuming_context[path] = @status
    end
  end

  def load_status(resuming_context, path)
    if resuming_context.has_key?(path)
      @status = Status::RUNNING
    end
  end

end
