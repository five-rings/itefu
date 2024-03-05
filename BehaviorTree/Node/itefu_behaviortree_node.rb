=begin
  BehaviorTree/Node
=end
module Itefu::BehaviorTree::Node

  # ノードの実行状態
  module Status
    READY   = :status_ready     # 実行する準備ができている（実行していない）
    RUNNING = :status_running   # 実行中（次のフレームでまだ実行される）
    SUCCESS = :status_success   # 成功
    FAILURE = :status_failure   # 失敗
  end

end
