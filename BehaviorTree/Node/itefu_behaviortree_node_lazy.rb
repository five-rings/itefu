=begin
  BehaviorTree/Node/子ノードの生成を遅延実行するノード
  @note このノードが評価（実行）されたときはじめて子ノードを実際に生成する
=end
class Itefu::BehaviorTree::Node::Lazy < Itefu::BehaviorTree::Node::Decorator
  attr_reader :evaluated

  def join_node(klass, *args, &block)
    if @evaluated
      super
    else
      # 生成するノードの情報だけ記録しておく
      @nodelist = NodeList.new(klass, *args, &block)
    end
  end
  
  def on_node_init
    unless @evaluated
      # 最初の実行時に子ノードを生成する
      @evaluated = true
      @nodelist.evaluate(self) if @nodelist
    end
  end

  # 生成する子ノードの情報
  class NodeList
    attr_reader :klass, :args, :block
    attr_reader :children

    def initialize(klass, *args, &block)
      @klass = klass
      @args = args
      @block = block
      @children = []
    end

    def join_node(klass, *args, &block)
      child = NodeList.new(klass, *args, &block)
      @children << child
      child
    end
    
    def evaluate(parent)
      node = parent.join_node(@klass, *@args, &@block)
      @children.each do |child|
        child.evaluate(node)
      end
    end
  end

end
