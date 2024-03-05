=begin
  BehaviorTree/Node/複数の子ノードを接続するノードの共通クラス
=end
class Itefu::BehaviorTree::Node::Composite < Itefu::BehaviorTree::Node::Base
  attr_reader :children

  # @return [Status] 子ノードの結果に応じたこのノードの結果
  def on_child_node_processed(child_status); Status::RUNNING; end

  # @return [Statu] 子ノードを全て実行し終えたときの結果
  def status_when_completes; Status::SUCCESS; end

  # 子ノードを接続する
  def join_node(klass, *args, &block)
    child = klass.new(*args, &block)
    child.node_joined(self)
    children << child
    child
  end

  # 子ノードを全て切断する
  def clear_children
    children.each(&:finalize)
    children.clear
  end

  def initialize(*args)
    super
    @children = []
  end

  def finalize
    super
    clear_children
  end

  def on_node_reset
    children.each(&:node_reset)
  end

  def on_node_init
    @index_to_process = 0
  end

  def on_node_process
    # 処理中の子ノードがないか探す
    @index_to_process ||= children.index {|child| child.running? } || 0

    # 順に処理
    while child = children[@index_to_process]
      # 子ノードを処理
      child_status = child.node_process
      # まだ処理中なので中断する
      return Status::RUNNING if child_status == Status::RUNNING

      # 処理し終えた
      returned_status = on_child_node_processed(child_status)
      @index_to_process += 1

      # このノードの結果が確定したので処理を終了する
      if returned_status != Status::RUNNING
        return returned_status
      end
    end
    # 全ての子ノードを実行し終えた
    status_when_completes
  end

  def save_status(resuming_context, path)
    children.each.with_index do |child, i|
      child.save_status(resuming_context, path + "#{i}/")
    end
  end

  def load_status(resuming_context, path)
    # 同時に複数の子ノードがRUNNINGになる派生クラスがあるかもしれないので
    # 全部調べる
    children.each.with_index do |child, i|
      child.load_status(resuming_context, path + "#{i}/")
      if child.running?
        @status = Status::RUNNING
      end
    end
    @index_to_process = nil
  end

#ifdef :ITEFU_DEVELOP
  def dump_status(indent = 0)
    super
    indent += 1
    children.each {|child| child.dump_status(indent) }
  end
#endif

end
