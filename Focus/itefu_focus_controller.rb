=begin
  フォーカスを与える対象を管理する
=end
class Itefu::Focus::Controller
  # @note フォーカスコントローラ自体もフォーカスを受け取ることができる.
  #       複数のフォーカスコントローラを生成し, そのうちの一つにだけフォーカスを与えるというような使い方が可能.
  include Itefu::Focus::Focusable

  def on_focused
    current.focus = true unless empty?
  end
  
  def on_unfocused
    current.focus = false unless empty?
  end
  
  # @return [Boolean] このフォーカスコントローラが有効か
  def active?; @focus; end

  # このフォーカスコントローラを有効にする
  # @return [Focus::Controller] レシーバー自身を返す
  def activate; self.focus = true; self; end

  # このフォーカスコントローラを無効にする
  # @return [Focus::Controller] レシーバー自身を返す
  def deactivate; self.focus = false; self; end


  # --------------------------------------------------
  #

  def initialize
    super
    @focus_graph = []
  end
  
  # @return [Focusable] 現在フォーカスの当たっているインスタンス
  def current
    @focus_graph.last
  end
  
  # @return [Boolean] フォーカスグラフが空か
  def empty?
    @focus_graph.empty?
  end

  # フォーカスグラフを空にする
  def clear
    unless empty?
      current.focus = false if active?
      @focus_graph.clear
    end
  end

  # 指定したインスタンスにフォーカスを与える
  # @param [Focusable] instance フォーカスを与えるインスタンス
  # @return [Focusable] フォーカスを与えたインスタンス
  def push(instance)
    if active?
      current.focus = false unless empty?
      @focus_graph << instance
      instance.focus = true
    else
      @focus_graph << instance
    end
    instance
  end

  # 一つ前のインスタンスにフォーカスを与える
  # @return [Focusable] 取り除かれた(今までフォーカスのあった)インスタンス
  def pop
    instance = @focus_graph.pop
    if active?
      instance.focus = false if instance
      current.focus = true unless empty?
    end
    instance
  end

  # フォーカスグラフの末尾を入れ替える
  # @param [Focusable] instance フォーカスを与えるインスタンス
  # @return [Focusable] フォーカスを与えたインスタンス
  def switch(instance)
    if active?
      if empty?
        @focus_graph << instance
      else
        current.focus = false
        @focus_graph[-1] = instance
      end
      instance.focus = true
    else
      @focus_graph.pop
      @focus_graph << instance
    end
    instance
  end

  # 指定したインスタンスにフォーカスを与え、フォーカスグラフを再構築する
  # @note フォーカスグラフがクリアされ、追加したインスタンスのみになる 
  # @param [Focusable] instance フォーカスを与えるインスタンス
  # @return [Focusable] instance フォーカスを与えたインスタンス
  def reset(instance)
    clear
    @focus_graph << instance
    instance.focus = true if active?
    instance
  end

  # 指定したインスタンスにフォーカスが合うまで、フォーカスグラフをまき戻す
  # @param [Focusable] instance フォーカスを与えるインスタンス
  # @return [Focusable] instance フォーカスを与えたインスタンス
  def rewind(instance)
    return nil if empty?
    return instance if instance.equal?(current)
    current.focus = false if active?

    # グラフをまき戻しながら探索する
    until empty?
      @focus_graph.pop
      if instance.equal?(current)
        instance.focus = true if active?
        return instance
      end
    end
    
    # 指定したインスタンスがグラフ内に存在しなかった
    nil
  end

#ifdef :ITEFU_DEVELOP
  # FocusGraphをダンプする
  def dump_log(out)
    Itefu::Debug::Log.notice "# FocusGraph", out
    @focus_graph.each do |instance|
      Itefu::Debug::Log.notice "#{instance.class} (#{instance.object_id})", out
    end if @focus_graph
  end
#endif

  # Controllerが入れ子になっているグラフからフォーカスの当たっているものを取得する
  def focused_instance
    current.focused_instance unless empty?
  end

end
