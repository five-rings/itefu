=begin
  BehaviorTree/Node/Randomノードに選ばれるときの重み付けを行う
=end
class Itefu::BehaviorTree::Node::Weight < Itefu::BehaviorTree::Node::Decorator
  attr_reader :weight

  # @param [Integer] weight このノードの重み(数値が大きいほど選ばれやすくなる)
  def on_initialize(weight)
    @weight = Utility::Math.max(1, weight)
  end
  
end
