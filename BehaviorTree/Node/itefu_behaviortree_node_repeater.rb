=begin
  BehaviorTree/Node/指定した回数、または無限に、子ノードの実行を繰り返すノード
  @note 指定回数を指定しなかった場合、子ノードのStatusに関わらず、無限に繰り返す
  @note 指定回数を指定した場合、指定回数に達する前でも、Failureが変えれば処理を中断する
=end
class Itefu::BehaviorTree::Node::Repeater < Itefu::BehaviorTree::Node::Decorator
  attr_reader :count_to_repeat
  
  # @param [Fixnum|NilClass] count_to_repeat 繰り返す回数、nilで無限に繰り返す
  def on_initialize(count_to_repeat)
    @count_to_repeat = count_to_repeat
  end
  
  def on_node_init
    @count = 0 if @count_to_repeat
  end
  
  def on_node_process
    if @count_to_repeat.nil?
      super
      return Status::RUNNING
    end

    # 1回未満だけ繰り返したことにする
    return Status::SUCCESS if @count_to_repeat < 1

    # 子を実行する
    returned_status = super
    return returned_status unless returned_status == Status::SUCCESS

    @count += 1
    if @count < @count_to_repeat
      Status::RUNNING
    else
      Status::SUCCESS
    end
  end

  def save_status(resuming_context, path)
    if running?
      resuming_context[path] = @count
    end
    super
  end

  def load_status(resuming_context, path)
    if c = resuming_context[path]
      @count = c
      @status = Status::RUNNING
    end
    super
  end

end
