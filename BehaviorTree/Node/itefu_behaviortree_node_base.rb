=begin
  BehaviorTree/Node/共通のクラス
=end
class Itefu::BehaviorTree::Node::Base
  include Itefu::BehaviorTree::Common
  attr_reader :status   # [Status] ノードのステータス
  attr_reader :context  # [Hash] ツリー内の全ノードで共有するデータ

  module Status
    include Itefu::BehaviorTree::Node::Status
  end

  # インスタンス生成時に実行される
  def on_initialize(*args); end

  # インスタンス破棄時に実行される
  def on_finalize; end

  # 他のノードに下に接続された際に呼ばれる
  def on_node_joined(parent); end

  # BehaviorTreeのノードトラバース前に呼ばれる
  def on_node_reset; end

  # このノードの実行前に呼ばれる
  def on_node_init; end

  # このノードの実行時に呼ばれる
  # @return [Status] ノードを実行した結果
  def on_node_process; Status::SUCCESS; end

  # ステータスが切り替わる際に呼ばれる
  # @return [Status] ノードを実行した結果を上書きする
  def on_node_status_changed(status); status; end

  def ready?;   status == Status::READY;   end
  def running?; status == Status::RUNNING; end
  def success?; status == Status::SUCCESS; end
  def failure?; status == Status::FAILURE; end


  def initialize(*args, &block)
    @status = Status::READY
    super
    on_initialize(*args, &block)
  end

  def finalize
    on_finalize
  end

  # ツリーのトラバース前に行われるリセット時の処理
  def node_reset
    @status = Status::READY unless running?
    on_node_reset
  end

  # ノードを処理する際に最初に呼ばれる処理
  def node_init
    on_node_init
  end

  # ノードの処理
  def node_process
    node_init if ready?
    @status = on_node_status_changed(on_node_process)
  end

  # 他のノードの子として接続されたときに呼ばれる
  def node_joined(parent)
    @context = parent.context if parent
    on_node_joined(parent)
  end

  # 現在の状態を保存する
  def save_status(resuming_context, path); end

  # 保存された状態を復元する
  def load_status(resuming_context, path); end

#ifdef :ITEFU_DEVELOP
  def dump_status(indent = 0)
    debug_output(" "*indent + "[#{status}] #{self.class}")
  end
#endif

end
