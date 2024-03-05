=begin
  BehaviorTree/Node/子を一つ接続するノードの共通クラス
=end
class Itefu::BehaviorTree::Node::Decorator < Itefu::BehaviorTree::Node::Base
  attr_reader :child

  # 子ノードを接続する
  def join_node(klass, *args, &block)
    old = child
    @child = klass.new(*args, &block)
    child.node_joined(self)
    old.finalize if old
    child
  end

  # 子ノードを切断する
  def clear_child
    if child
      child.finalize
      child = nil
    end
  end

  def finalize
    super
    clear_child
  end

  def on_node_reset
    child.node_reset if child
  end

  def on_node_process
    if child
      child.node_process
    else
      Status::SUCCESS
    end
  end

  def save_status(resuming_context, path)
    if child
      child.save_status(resuming_context, path + "/")
    end
  end

  def load_status(resuming_context, path)
    if child
      child.load_status(resuming_context, path + "/")
      if child.running?
        @status = Status::RUNNING
      end
    end
  end

#ifdef :ITEFU_DEVELOP
  def dump_status(indent = 0)
    super
    child.dump_status(indent + 1) if child
  end
#endif

end
