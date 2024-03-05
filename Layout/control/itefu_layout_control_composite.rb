=begin
  Layoutシステム/複数の子要素を持つコントロール
=end
class Itefu::Layout::Control::Composite < Itefu::Layout::Control::Base
  attr_reader :children         # [Array<Control::Base>] 子コントロール
  attr_bindable :items          # [Array] 子要素を生成するための内容
  attr_accessor :item_template  # [Proc] 子を生成する際のテンプレート
  
  # 子コントロールに追加される要素
  module CompositedItem
    attr_accessor :item, :item_index
  end

  # 子を追加するときのコンテキスト
  # itemsから子コントロールを生成するときの情報を渡すのに使用する
  AddingContext = Struct.new(:item, :index)
  
  def initialize(*args)
    super
    @children = []
    
    # レイアウト定義から生成されたコントロール
    @static_controls = []
    
    # itemsから自動生成されたコントロール
    # 再利用する際の探索のため、item.hash順でソートされなければならない
    @dynamic_controls = []
  end

  # 終了処理
  def impl_finalize
    clear_children
  end
  
  # コントロールを生成し子コントロールとして追加する
  # @note @adding_contextが設定されていると、itemsからの動的生成とみなす
  # @param [Class] klass 生成するコントロールの型
  # @param [Array] args 生成時に渡す任意の引数
  # @return [Control::Base] 追加したコントロール
  def add_child_control(klass, *args)
    disarrange
    child = create_child_control(klass, *args)
    child.extend CompositedItem
    if context = @adding_context
      child.item = context.item
      child.item_index = context.index
      @dynamic_controls << child
    else
      @static_controls << child
    end
    children << child
    child
  end

  # 子コントロールを全て解放する  
  def clear_children
    children.each(&:finalize)
    children.clear
    @static_controls.clear
    @dynamic_controls.clear
  end
  
  # 子コントロールのメソッドを呼ぶ
  def iterate_sub_controls(method, *args)
    if args.empty?
      children.each(&method)
    else
      children.each {|child| child.send(method, *args) }
    end
  end

  # 再整列が必要な状態にする
  def disarrange(control = nil)
    if control && self.width != Size::AUTO && self.height != Size::AUTO
      @disarranged = true
    else
      super
    end
  end

  # 再整列
  def rearrange
    if @disarranged
      if self.takes_space?
        impl_measure(self.content_width, self.content_height)
        impl_arrange(self.screen_x, self.screen_y, self.actual_width, self.actual_height)
      end
      @disarranged = false
    else
      children.each(&:rearrange)
    end
  end


  # 更新
  def impl_update
    reconstruct_children
    children.each(&:update)
  end
  
  # 描画
  def impl_draw
    children_that_takes_space.each do |child|
      next unless in_drawing_bound?(child)
      child.draw
    end
  end
  
  # arrange済みのコントロールが描画領域内に存在するか
  def in_drawing_bound?(control)
    case
    when control.screen_y + control.actual_height <= self.screen_y
      false
    when control.screen_y >= self.screen_y + self.actual_height
      false
    when control.screen_x + control.actual_width <= self.screen_x
      false
    when control.screen_x >= self.screen_x + self.actual_width
      false
    else
      true
    end
  end

  # 描画領域内にある子のみ描画する
  def partial_draw(controls)
    is_drawn = false
    controls.each do |child|
      if in_drawing_bound?(child)
        child.draw
        is_drawn = true
      elsif is_drawn
        break
      else
        next
      end
    end
  end
  
  # 場所を占有する子のみ取得する
  def children_that_takes_space
    children.select(&:takes_space?)
  end
  
  # 属性更新時の処理
  def binding_value_changed(name, old_value)
    case name
    when :items
      # ここで即座に子を構築すると、定義ファイルを書くときに、
      # templateが未設定だったり、ベタ書きする子が後から定義されたりして困るので、後で行うようにする
      @items_changed = true
    end
    super
  end
  
  # @return [Fixnum] 次の子のindexを返す
  def next_child_index(operation, child_index)
    raise Exception::NotImplemented
  end
  
  # @return [Boolean] indexの指定位置がラップしたか
  def child_index_wrapped?(operation, child_index, old_index)
    raise Exception::NotImplemented
  end
  
  # @return [Fixnum] index指定がない場合の初期値
  def default_child_index(operation)
    0
  end
  
  # @return [Finxum] 指定した位置にある子のindex
  def next_index_by_position(x, y)
    self.screen_x && self.screen_y && # arrangeされていることを保証
    # このコントロールの範囲内なら
    x >= self.screen_x &&
    x <  self.screen_x + self.actual_width &&
    y >= self.screen_y &&
    y <  self.screen_y + self.actual_height &&
    # 対応する子コントロールを返す
    rfind_child_index {|child|
      next false unless child.takes_space?
      x >= child.screen_x &&
      x <  child.screen_x + child.actual_width &&
      y >= child.screen_y &&
      y <  child.screen_y + child.actual_height
    } || nil
  end
  
  # indexから該当する子コントロールを取得する
  # @return [Control::Base|Array<Control::Base>]
  # @note 配列を返す可能性もあることに注意する
  # @warning child_indexは正の整数しか受け付けない
  def child_at(child_index)
    child_index && child_index >= 0 && children.at(child_index)
  end
  
  # @return [Fixnum] 子コントロールの数を取得する
  def children_size
    children.size
  end
  
  # @return [Fixnum] 子コントロールのindexを探す
  def find_child_index(control = nil, &block)
    if control
      children.index(control, &block)
    else
      children.index(&block)
    end
  end
  
  # @return [Fixnum] 子コントロールのindexを探す
  def rfind_child_index(control = nil, &block)
    if control
      children.rindex(control, &block)
    else
      children.rindex(&block)
    end
  end

  
private

  # itemsに変更があれば子コントロールを再構築する
  def reconstruct_children
    if @items_changed
      @items_changed = false
      construct_children(self.items)
    end
  end

  # itemsから子コントロールを生成する
  def construct_children(items)
    children.clear
    corrupt

    if items && template = item_template
      construct_dynamic_controls(items, template)
    else
      @dynamic_controls.each(&:finalize)
      @dynamic_controls.clear
    end

    construct_static_controls
    execute_callback(:constructed_children, items)
  end
  
  # itemsから動的に追加する分の構築
  def construct_dynamic_controls(items, template)
    @adding_context = AddingContext.new

    if items.equal? @old_items
      # 差分モード
      replacements = @dynamic_controls
      @dynamic_controls = []
      # 減る場合でadd_newしない場合はrearrange必要
      #   増える場合はadd_newするのでrearrange不要
      need_to_disarrange = items.size < replacements.size
      # 
      items.each.with_index do |item, index|
        # 既に同じitemに対するコントロールが作成済みであれば使いまわす
        if pos = Utility::Array.binary_search(item.hash, replacements) {|element| element.item.hash }
          control = replacements.delete_at(pos)
          add_replacement_control(control, index)
        else
          add_new_control(item, index, template)
          # add_newすればrearrangeされる
          need_to_disarrange = false
        end
      end
      disarrange if need_to_disarrange
      # 再利用されなかったコントロールは不要なので開放する
      replacements.each(&:finalize)
    else
      # 新規モード
      @dynamic_controls.each(&:finalize)
      @dynamic_controls.clear
      items.each.with_index do |item, index|
        add_new_control(item, index, template)
      end
    end

    @dynamic_controls.sort_by! {|c| c.item.hash }
    @old_items = items
    @adding_context = nil
  end

  # レイアウト定義で静的に追加された分の構築
  def construct_static_controls
    # レイアウトの定義で追加される分
    @static_controls.each do |child|
      if child.item_index
        # indexが指定されている場合は指定の位置に挿入する
        pos = Utility::Array.lower_bound(child.item_index, children) {|element| element.item_index }
        children.insert(pos, child)
      else
        children << child
      end
    end    
  end
  
  # 既に生成済みのコントロールと置き換える
  def add_replacement_control(child, index)
    child.item_index = index
    @dynamic_controls << child
    children << child
    child
  end

  # 新しいコントロールを追加する
  def add_new_control(item, index, template)
    @adding_context.item = item
    @adding_context.index = index
    instance_exec(item, index, &template)
  end

end
