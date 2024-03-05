=begin
　　入力コマンドを表現するクラス
=end
class Itefu::Input::Command
  attr_reader :strokes
  
  def nonblocking?; @nonblocking; end # [Boolean] 非同期コマンドか
  def executing?; @executing; end     # [Boolean] 実行中か
  
  def initialize
    @strokes = []
    @callbacks = []
  end
  
  # 非同期コマンドの設定を行う
  # @param [Boolean] value 非同期コマンドにするか
  # @note 非同期コマンドは1ストロークコマンドにのみ対応
  # @note 非同期コマンドに複数ストロークを割り当てた場合は一つ目のストローク以外は無視される
  def set_nonblocking(value)
    @nonblocking = value
#ifdef :ITEFU_DEVELOP
    if @nonblocking && @strokes.size > 1
      ITEFU_DEBUG_OUTPUT_WARNING "Itefu::Command having #{@strokes.size} strokes is set to non-blocking-mode."
      ITEFU_DEBUG_OUTPUT_WARNING "The second and later strokes will be ignored."
    end
#endif
    self
  end

  # コマンドが実行される際に呼ばれるコールバックを追加する
  def add_callback(*args, &block)
    @callbacks.concat(args)
    @callbacks << block if block
    self
  end
  
  # コマンドを実行するのに必要なストロークを追加する
  # @param [Object] key Itefu::Input::Semanticsで指定しているキーの意味
  # @param [Method] method キー入力判定の方法(triggered?など)
  # @param [Array<Object>] modifiers 同時押しすべき任意のキー
  def add_stroke(key, method, *modifiers)
    @strokes << { key: key, method: method, modifiers: modifiers }
#ifdef :ITEFU_DEVELOP
    if @nonblocking && @strokes.size > 1
      ITEFU_DEBUG_OUTPUT_WARNING "Itefu::Command under non-blocking-mode accepts only 1 stroke but #{@strokes.size} strokes are added."
      ITEFU_DEBUG_OUTPUT_WARNING "The second and later strokes will be ignored."
    end
#endif
    self
  end
  
  # @return [Boolean] コマンドで指定されているキーストロークを入力しているか
  # @param [Fixnum] stroke_count 何番目のストロークか
  # @param [Itefu::Input::Manager]
  def stroked?(stroke_count, input_manager)
    return false unless stroke = @strokes[stroke_count]
    return false unless stroke[:modifiers].all? {|key|
      input_manager.pressed?(key)
    }
    input_manager.send(stroke[:method], stroke[:key])
  end
  
  # @return [Boolean] コマンドの実行するキー入力が解除されたか
  # @param [Itefu::Input::Manager]
  def finished?(input_manager)
    stroked?(@strokes.size - 1, input_manager).!
  end
  
  # コマンドを実行する
  # @param [Array<Object>] args コールバックに渡す任意の引数
  def execute(*args)
    @executing = true
    @callbacks.each do |cb|
      cb.call(*args)
    end
  end
  
  # コマンドの実行状態を解除する
  def finish
    @executing = false
  end
  
end
