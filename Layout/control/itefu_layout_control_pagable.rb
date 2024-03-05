=begin
  Layoutシステiム/ページング機能を使用できるようにする
  @note Control::Compositeにmix-inして使用する
=end
module Itefu::Layout::Control::Pagable
  include Itefu::Layout::Definition
  extend Itefu::Layout::Control::Bindable::Extension
#ifdef :ITEFU_DEVELOP
  extend Utility::Module.expect_for(Itefu::Layout::Control::Composite)
#endif
  attr_bindable :page_size    # [Fixnum] 1ページ内の要素数
  attr_bindable :page_count   # [Fixnum] 現在のページ数
  
  # Selectorだった場合、カーソルの移動でページを変更できるようにする
  # @note PagableのあとにSelectorをmix-inすると機能しない
  def on_cursor_moved(operation, index, old_index)
    if child_index_wrapped?(operation, index, old_index)
      case operation
      when Operation::MOVE_LEFT, Operation::MOVE_UP
        decrement_page_count
      when Operation::MOVE_RIGHT, Operation::MOVE_DOWN
        increment_page_count
      end
    end
    set_cursor_index(old_index, operation) unless index
  end
 
  def page_count_max(page_size = self.page_size)
    (self.items.size - 1) / page_size
  end
  
  def increment_page_count
    self.page_count = Utility::Math.wrap(0, page_count_max, self.page_count + 1)
  end
  
  def decrement_page_count
    self.page_count = Utility::Math.wrap(0, page_count_max, self.page_count - 1)
  end

  
  # 属性更新時の処理
  def binding_value_changed(name, old_value)
    case name
    when :page_size, :page_count
      @items_changed = true
    end
    super
  end
  
  # 子要素を生成する際にページ設定に応じた内容を与える
  def construct_children(items)
    size = self.page_size
    count = self.page_count
    if items && count && size
      count = Utility::Math.clamp(0, page_count_max(size), count)
      super(items[count * size, size])
    else
      super
    end
  end

end
