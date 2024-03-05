=begin
　　入力コマンドを管理・実行するクラス
=end
class Itefu::Input::Commander
  include Itefu::Utility::State::Context
  
  Context = Struct.new(:stroke_count, :commands)
  
  module State
    module FirstStroke
      extend Itefu::Utility::State::Callback::Simple
      define_callback :attach, :update
    end
    module WaitForNextStroke
      extend Itefu::Utility::State::Callback::Simple
      define_callback :update
    end
    module AdditionalStroke
      extend Itefu::Utility::State::Callback::Simple
      define_callback :update
    end
    module Executing
      extend Itefu::Utility::State::Callback::Simple
      define_callback :update
    end
  end
  
  def initialize
    super
    @context = Context.new(0, nil)
    @commands = []
    @executing_commands = []
    change_state(State::FirstStroke)
  end

  # 未入力状態にする
  def reset
    @executing_commands.each(&:finish)
    @executing_commands.clear
    change_state(State::FirstStroke)
  end

  # 外部で生成したコマンドを追加する
  # @return [Itefu::Input::Commander] 自分自身を返す
  def add_command(command)
    @commands << command
    self
  end
  
  # @return [Itefu::Input::Command] 新しくコマンドを追加して、そのコマンドを返す
  # @note 定義時にメソッドチェーンで書くためのもの。
  def new_command(command_klass = Itefu::Input::Command, *args, &block)
    command_klass.new(*args, &block).tap {|c|
      @commands << c
    }
  end
  
  # 入力処理を行うフレームに毎回呼ぶ
  # @param [Itefu::Input::Manager]
  # @param [Array<Object>] コールバックに渡す任意のパラメータ
  def update(input_manager, *args)
    update_executing_commands(input_manager, *args)
    update_nonblocking_commands(input_manager, *args)
    update_state(input_manager, *args)
  end
  
  def on_state_first_stroke_attach
    # 他ストローク判定に使うワークを初期化する
    @context.stroke_count = 0
    @context.commands = @commands
  end

  # 1ストローク目を待つ
  def on_state_first_stroke_update(input_manager, *args)
    if check_stroked(input_manager)
      # 実行するか確認する
      if execute_command(input_manager, *args)
        # 1ストロークコマンド
        change_state(State::Executing)
      else
        # 多ストロークコマンドの1ストローク目だった
        change_state(State::WaitForNextStroke)
      end
    end
  end
  
  # ある入力が何らかのコマンドで指定されたキーストロークであると判定されたとき、その入力が解除され次の入力がはじまるのを待つ
  def on_state_wait_for_next_stroke_update(input_manager, *args)
    if input_manager.triggered_any?
      if check_stroked(input_manager)
        # 何らかのキーが押され、いずれかのコマンドで指定された条件を満たした
        if execute_command(input_manager, *args)
          # あるコマンドの実行条件を満たした
          change_state(State::Executing)
        else
          # 多ストロークコマンドのまだ途中だった
          change_state(State::WaitForNextStroke)
        end
      else
        # 何らかのキーが押されたがまだどのコマンドかは確定していない
        # 更にキーが押されると確定する可能性があるのでそれを待つ
        change_state(State::AdditionalStroke)
      end
    end
  end
 
  # 多ストロークコマンドの入力を待つ
  def on_state_additional_stroke_update(input_manager, *args)
      if check_stroked(input_manager)
        if execute_command(input_manager, *args)
          # あるコマンドの実行条件を満たした
          change_state(State::Executing)
        else
          # Nストロークコマンドのまだ途中だった
          change_state(State::WaitForNextStroke)
        end
      else
        # どのコマンドで指定されたキーストロークも行われず、キーを離した場合、条件を満たすキー入力を行わなかったとみなす
        if input_manager.released_any?
          change_state(State::FirstStroke)
        end
      end
  end
  
  # 他の入力と排他的なコマンドの実行中
  def on_state_executing_update(input_manager, *args)
    commanded = @executing_commands.find {|command|
      command.nonblocking?.! && command.finished?(input_manager).!
    }
    unless commanded
      change_state(State::FirstStroke)
    end
  end
  
private

  # 指定したキーストロークを満たしたコマンドがないかチェックしする
  def check_stroked(input_manager)
    stroked = @context.commands.select {|command|
      command.nonblocking?.! && command.stroked?(@context.stroke_count, input_manager)
    }
    unless stroked.empty?
      @context.stroke_count += 1
      @context.commands = stroked
      true
    end
  end
  
  # 指定されたすべてのキーストロークを行ったコマンドを実行する
  def execute_command(input_manager, *args)
    commanded = @context.commands.find {|command|
      command.strokes.size == @context.stroke_count && command.executing?.!
    }
    if commanded
      commanded.execute(input_manager, *args)
      @executing_commands << commanded
    end
    commanded
  end
  
  # 実行中のコマンドの処理
  def update_executing_commands(input_manager, *args)
    @executing_commands.delete_if do |command|
      if command.finished?(input_manager)
        # コマンド入力を止めた
        command.finish
        true
      else
        # 条件を満たしている間は実行し続ける
        # triggered?などは１回限りだが、pressed?のように繰り返し呼ばれるものもある
        command.execute(input_manager, *args)
        false
      end
    end
  end
  
  # 非同期コマンドの入力があれば実行する
  def update_nonblocking_commands(input_manager, *args)
    commanded = @commands.find {|command|
      command.nonblocking? && command.executing?.! && command.strokes.size == 1 && command.stroked?(0, input_manager)
    }
    if commanded
      commanded.execute(input_manager, *args)
      @executing_commands << commanded
    end
  end
    
end
