=begin
  BehaviorTree/Node/一度だけ実行されるノード
  @note 二回目以降は何もせずにFailureを返す
=end
class Itefu::BehaviorTree::Node::Initializer < Itefu::BehaviorTree::Node::Decorator
  attr_reader :initialized

  def on_node_process
    return Status::FAILURE if @initialized

    returned_status = super
    unless returned_status == Status::RUNNING
      @initialized = true
    end
    returned_status
  end

  def save_status(resuming_context, path)
    if @initialized
      resuming_context[path] = true
    else
      super
    end
  end

  def load_status(resuming_context, path)
    if resuming_context.has_key?(path)
      @initialized = true
    else
      super
    end
  end

end
