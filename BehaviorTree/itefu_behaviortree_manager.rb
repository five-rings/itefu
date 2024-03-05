=begin
  BehaviorTreeのRootノードを管理する
=end
module Itefu::BehaviorTree::Manager
  attr_reader :bt_root_nodes

  def bt_root_node_klass; Itefu::BehaviorTree::Node::Root; end

  def initialize(*args)
    super
    @bt_root_nodes = []
  end

  def finalize_bt
    clear_bt_trees
  end

  def update_bt_trees
    # 不要になったBTを削除
    @bt_root_nodes.delete_if do |root_node|
      unless root_node.alive?
        root_node.finalize
        true
      end
    end
    # BTの更新
    @bt_root_nodes.each(&:update)
  end

  # @return [Itefu::BehaviorTree::RootNode] 新しく追加されたビヘイビアツリーのルートノード
  # @param [Hash] context このツリーで共有するデータ
  def add_bt_tree(klass, context, *args, &block)
    root_node = bt_root_node_klass.new
    root_node.create_context(context)
    root_node.node_joined(nil)
    root_node.join_node(klass, *args, &block)
    @bt_root_nodes << root_node
    root_node
  end

  def clear_bt_trees
    @bt_root_nodes.each(&:finalize)
    @bt_root_nodes.clear
  end

end
