=begin
  BehaviorTree/Node/ブロックを実行した結果に応じて成否が決まるノード
=end
class Itefu::BehaviorTree::Node::Conditional < Itefu::BehaviorTree::Node::Decorator
  attr_accessor :proc_condition

  def on_initialize(proc_cond)
    @proc_condition = proc_cond
  end
  
  def on_node_process
    return super if running?
    begin
      return Status::FAILURE unless proc_condition
      return Status::FAILURE unless proc_condition.call(self)
    rescue => e
      show_exception(self.class.to_s, e)
      return Status::FAILURE
    end
    super
  end

end
