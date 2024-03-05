=begin
  Layoutシステム/項目を選択可能にする
  @note Control::Compositeにmix-inして使用する
=end
module Itefu::Layout::Control::Selector
  include Itefu::Layout::Definition
  include Itefu::Layout::Control::Focusable
  include Itefu::Layout::Control::Intrusivable
#ifdef :ITEFU_DEVELOP
  extend Utility::Module.expect_for(Itefu::Layout::Control::Composite)
#endif
  attr_accessor :cursor_index           # [Fixnum] カーソル位置
  attr_accessor :cursor_index_changing      # [Proc] カーソルの変更処理に割り込みたいときに設定する
  attr_accessor :custom_default_child_index # [Proc] フォーカスを得たときのデフォルトカーソルを変更する

  def on_active_effect(index); end        # 項目が選択された
  def on_deactive_effect(index); end      # 項目の選択が解除された
  def on_suspend_effect(index); end       # 項目の選択が一時的に解除された
  def on_decide_effect(index); end        # 決定された
  def on_cancel_effect(index); end        # キャンセルされた
  # 移動操作によってカーソルが変わった
  def on_cursor_moved(operation, index, old_index); end
  # 選択操作によってカーソルが変わった
  def on_cursor_selected(x, y, index, old_index); end
  
  # 子コントロールにmix-inする、選択可能なコントロールを表すクラス
  def selectable_klass; Itefu::Layout::Control::Selectable; end

  # @return [Boolean] objectへの自動遷移が可能か
  def self.intrusivable?(object)
    Itefu::Layout::Control::Intrusivable === object && object.unintrusivable?.!
  end


  def self.extended(object)
    # 既に生成済みの子を選択項目に拡張する
    klass = object.selectable_klass
    object.children.each do |child|
      child.extend klass unless Itefu::Layout::Control::Unselectable === child
    end
  end

  # 子を生成する際に選択項目に拡張する
  def add_child_control(klass, *args)
    child = super
    child.extend selectable_klass unless Itefu::Layout::Control::Unselectable === child
    child
  end
  
  def impl_update
    reconstruct_children
    update_cursor_selection
    super
  end

  # カーソルのindexを指定する際に、カーソルの変更のための準備もする
  def cursor_index=(value)
    # 同一フレームで何度もカーソルが変更される可能性があるので
    # いちいち対応せず、あとでまとめてカーソル処理を行う
    if value.nil? || child_selectable?(value) || @items_changed
      @index_to_activate = value if focused?
      @cursor_index = value
    end
    @select_args = nil
  end

  # フォーカスを得たときの処理
  def on_focused
    reset_active_cursor
  end
  
  # フォーカスを失ったときの処理
  def on_unfocused
    if @index_activated
      # カーソルがある場合は、それをdeactivateしてからフォーカスを外す
      on_deactive_effect(@index_activated)
      @index_activated = nil
    end
    @index_to_activate = nil
  end
  
  # 何かしらの操作が行われたときに呼ばれる
  def on_operation_instructed(operation, *args)
    case operation
    when Operation::DECIDE
      x, y = args
      operate_decide(x, y)
    when Operation::CANCEL
      operate_cancel
    when Operation::MOVE_LEFT,
         Operation::MOVE_RIGHT,
         Operation::MOVE_UP,
         Operation::MOVE_DOWN
      operate_move(operation)
    when Operation::MOVE_POSITION
      x, y = args
      operate_select(x, y) if x && y
    else
      # 未知の操作が行われた
      execute_callback(:unknown_operation_instructed, operation, *args)
    end
  end
  
  def focused_control
    child_at(self.cursor_index)
  end
  
  # @return [Boolean] 指定したindexは選択可能か
  def child_selectable?(child_index)
    control = child_at(child_index)
    control && control.selectable?
  end
  
  def child_unselectable?(child_index)
    control = child_at(child_index)
    control && control.unselectable?
  end
  
  # @return [Fixnum] 選択可能な子を探してそのindexを返す
  def find_selectable_child_index(base_index = 0)
    base_index = children_size + base_index if base_index < 0
    index = base_index
    while child_unselectable?(index)
      index += 1
    end 
    return index  if child_at(index)
    
    index = base_index
    begin
      index -= 1
    end until index < 0 || child_selectable?(index)
    child_at(index) && index
  end

  # @return [Boolean] 指定した座標にクリック可能な要素があるか
  # @note 自動遷移も考慮してチェックする
  def clickable?(x, y)
    control = self
    begin
      next_index = control.next_index_by_position(x, y)
      control = next_index && control.child_at(next_index)
    end while Itefu::Layout::Control::Selector.intrusivable?(control) && control.selectable?
    control && control.selectable?
  end
  
  # 前の項目のカーソルをサスペンドしてからフォーカスを切り替える
  def push_focus(id)
    # deactivateされないようにカーソルを変更する
    index = @index_activated
    @index_activated = nil
    # 子にフォーカスを移動
    c = super
    # deactivateするかわりにsuspendする
    @index_activated = index
    on_suspend_effect(index)
    child_at(index).select_suspend if child_selectable?(index)
    c
  end
  
  # 自動遷移によりフォーカスを引き受ける
  def take_focus_by_moving(owner, operation)
    @intrusived = owner
    index = find_selectable_child_index(default_child_index(operation))
    set_cursor_index(index, operation)
    root.view.push_focus(self)
  end
  
  # 自動遷移によりフォーカスを引き受ける
  def take_focus_by_selecting(owner, x, y)
    @intrusived = owner
    index = next_index_by_position(x, y)
    set_cursor_index(index, x, y)
    root.view.push_focus(self)
  end
 

protected

  # 決定操作を行う
  # @note x, yはnilを指定しても良い
  def operate_decide(x, y)
    current_index = self.cursor_index

    if x && y
      # タッチでの決定
      touched_index = next_index_by_position(x, y)
      if current_index != touched_index
        # タッチデバイスなど、未選択のものに対して直接決定できる場合、まずは選択状態にする
        return operate_select(x, y)
      end
    end
    
    # current_index に対して決定した
    on_decide_effect(current_index)
    execute_callback(:decided, current_index, x, y)
    child_at(current_index).select_decide if child_selectable?(current_index)
  end

  # キャンセル操作を行う
  def operate_cancel
    current_index = self.cursor_index
    on_cancel_effect(current_index)
    execute_callback(:canceled, current_index)
    child_at(current_index).select_cancel if child_selectable?(current_index)
    pop_focus
    # 入れ子の場合は親にもcancelを伝播させる
    if @intrusived
      @intrusived.operate_cancel
      @intrusived = nil
    end
  end

  # カーソルの移動操作を行う
  def operate_move(operation)
    return unless current_index = self.cursor_index

    # 次のカーソル位置を取得する
    next_index = current_index
    begin
      next_index = next_child_index(operation, next_index)
      # (移動先がない or 一周してしまった or 選択可能な項目が選ばれる) まで操作を繰り返す
    end until next_index.nil? || next_index == current_index || child_selectable?(next_index)

    # 必要に応じてカーソル位置の変換を行う
    next_index = cursor_index_changing.call(self, next_index, current_index, operation) if cursor_index_changing 
  
    # ラップしていて委譲されていた場合は親に戻る
    if next_index && @intrusived && child_index_wrapped?(operation, next_index, current_index)
      owner_current = @intrusived.cursor_index
      owner_next = owner_current
      begin
        owner_next = @intrusived.next_child_index(operation, owner_next)
      end until owner_next.nil? || owner_next == owner_current || @intrusived.child_selectable?(owner_next)
      if owner_next && owner_next != owner_current
        move_back_to_parent_selector(operation)
        # このコントロールでは操作が起こらなくて良いのであとの処理は中断する
        return
      end
    end

    if next_index
      # カーソル位置の変更
      set_cursor_index(next_index, operation)
    end
    on_cursor_moved(operation, next_index, current_index)
    execute_callback(:cursor_moved, operation, next_index, current_index)
  end

  # カーソルの選択操作を行う
  def operate_select(x, y)
    current_index = self.cursor_index
    next_index = next_index_by_position(x, y)
    
    # 必要に応じてカーソル位置の変換を行う
    next_index = cursor_index_changing.call(self, next_index, current_index, x, y) if cursor_index_changing 
    
    if next_index
      # カーソル位置の変更
      if next_index != current_index && child_selectable?(next_index)
        set_cursor_index(next_index, x, y)
        on_cursor_selected(x, y, next_index, current_index)
        execute_callback(:cursor_selected, x, y, next_index, current_index)
      end

    elsif @intrusived
      # 範囲外をクリックした場合は親に戻る可能性があるのでチェックする
      owner_current = @intrusived.cursor_index
      owner_next = @intrusived.next_index_by_position(x, y)
      if owner_next && owner_next != owner_current && @intrusived.clickable?(x, y)
        select_back_to_parent_selector(x, y)
        return
      end
    end
  end


  # 自動遷移してきた親に戻る 
  def move_back_to_parent_selector(operation)
    @intrusived = nil
    root.view.pop_focus
    root.view.focus.current.operate_move(operation)
  end

  # 自動遷移してきた親に戻る 
  def select_back_to_parent_selector(x, y)
    @intrusived = nil
    root.view.pop_focus
    root.view.focus.current.operate_select(x, y)
  end

  
private

  # カーソルを設定する
  def set_cursor_index(index, *args)
    self.cursor_index = index
    @select_args = args
  end
  
  # デフォルトのカーソル位置を変更可能にする
  def default_child_index(operation)
    if custom_default_child_index
      if index = custom_default_child_index.call(self, operation)
        return index
      end
    end
    super
  end

  # 指定したSelectorに自動遷移する
  def intrude_to(selected_control, x = nil, y = nil)
    if x && y
      selected_control.take_focus_by_selecting(self, x, y)
    else
      selected_control.take_focus_by_moving(self, x)
    end
  end

  # カーソルの選択処理を行う
  def update_cursor_selection
    if @index_to_activate
      # 再構築された結果、選択不可能な子にカーソルがある可能性がある
      unless child_selectable?(@index_to_activate)
        @cursor_index = @index_to_activate = find_selectable_child_index(@index_to_activate)
      end
      
      # 前のカーソルをdeactivateし、新しいカーソルをactivateする
      if @index_activated
        on_deactive_effect(@index_activated) 
        child_at(@index_activated).select_deactivate if child_selectable?(@index_activated)
      end
      on_active_effect(@index_to_activate)
      child_at(@index_to_activate).select_activate if child_selectable?(@index_to_activate)
      execute_callback(:cursor_changed, @index_to_activate, @index_activated)
      @index_activated = @index_to_activate
      @index_to_activate = nil

      # 可能であれば自動的に遷移する
      control = child_at(@index_activated)
      if Itefu::Layout::Control::Selector.intrusivable?(control)
        intrude_to(control, *@select_args)
      end
    end
    @select_args = nil
  end
  
  # 子が再構築されると、いままでカーソルがなくても、設定できる可能性がある
  def construct_children(items)
    super
    reset_active_cursor if focused?
  end
  
  # 現在のカーソルを再度アクティブにする、カーソルがなければ何か選べるものを設定する
  def reset_active_cursor
    @index_to_activate = self.cursor_index
    set_cursor_index find_selectable_child_index unless @index_to_activate
  end

end
