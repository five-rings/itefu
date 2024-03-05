=begin
  デバッグメニュー
=end
class Itefu::Scene::DebugMenu < Itefu::Scene::Base
  include Itefu::Layout::View::Proc
  include Itefu::Layout::View::Debug
  include Itefu::Layout::View::IconCursor
  include Itefu::Layout::Control
  include Itefu::Layout::Definition
  attr_reader :args
  attr_reader :block

  def caption; ""; end
  def menu_list(m); raise Itefu::Exception::NotImplemented; end
  def on_item_selected(index, *args); end
  def on_canceled; end

  def viewmodel_klass; ViewModel; end

  # --------------------------------------------------
  # 内部で使用する型
  # 

  class MenuList
    Item = Struct.new(:label, :data)
    attr_reader :items
    
    def initialize
      clear
    end
    
    def clear
      @items = []
    end
    
    def add_item(label, *args)
      @items << Item.new(label, args)
    end
    
    def add_separator
      @items << nil
    end
  end

  class ViewModel
    include Itefu::Layout::ViewModel
    attr_observable :caption
    attr_observable :menu_items
    def initialize
      self.menu_items = []
      self.caption = nil
    end
  end
  
  class CursorIndex
    def initialize(index)
      update(index)
    end
    
    def update(index)
      @cursor_index = index
    end
    
    def to_i
      @cursor_index
    end
  end
  
  module MoveMost
    attr_accessor :move_most
    Operation = Itefu::Layout::Definition::Operation

    def operate_move(operation)
      input = $itefu_application.system(Itefu::Input::Manager)
      status = input && input.find_status(Itefu::Input::Status::Win32)
      self.move_most = status && status.pressed?(Itefu::Input::Win32::Code::VK_SHIFT)
      super
    end

    def next_child_index(operation, child_index)
      if self.move_most
        case operation
        when Operation::MOVE_LEFT, Operation::MOVE_UP
          children.index {|child| child.selectable? }
        when Operation::MOVE_RIGHT, Operation::MOVE_DOWN
          children.rindex {|child| child.selectable? }
        end
      else
        super
      end
    end
  end

  # --------------------------------------------------
  # クラスの実装
  # 

  def refresh_menulist(menulist)
    @viewmodel.menu_items.modify(menulist.items)
  end

  def refresh_caption(text)
    @viewmodel.caption = text
  end
  
  def setup_layout
    refresh_caption(caption)
    refresh_menulist(MenuList.new.tap {|v| menu_list(v) })
    define_layout
    control(:menu).add_callback(:decided, method(:decided))
    control(:menu).add_callback(:canceled, method(:canceled))
  end

  def define_layout
    context = @viewmodel
    load_layout(context) {
      _(Grid) {
        add_col_separator 30
        attribute width: 1.0, height: 1.0,
                  margin: const_box(10)
        
        _(Label) {
          attribute grid_row: 0, grid_col: 0,
                    font_size: 24,
                    text: binding { context.caption }          
        }
        
        _(Cabinet) {
          extend Drawable
          extend Cursor
          extend Scrollable.option(:ControlViewer, :CursorScroller, :LazyScrolling)
          extend ScrollBar
          extend MoveMost
          attribute name: :menu,
                    grid_row: 0, grid_col: 1,
                    width: 1.0,
                    height: Size::AUTO,
                    horizontal_alignment: Alignment::LEFT,
                    vertical_alignment: Alignment::TOP,
                    content_alignment: Alignment::STRETCH,
                    orientation: Orientation::VERTICAL,
                    scroll_direction: Orientation::HORIZONTAL,
                    items: binding { context && context.menu_items },
                    item_template: proc {|item|
           if item
            _(Label) {
              attribute text: item.label,
                        horizontal_alignment: Alignment::LEFT,
                        vertical_alignment: Alignment::CENTER,
                        margin: const_box(0, 0, -2, 10),
                        font_size: 20,
            }
          else
            _(Unselectable, Separator) {
              attribute width: 1, height: 3,
                        separate_color: Itefu::Color.White,
                        padding: const_box(1),
                        margin: const_box(4)
            }
          end
                    }
        }
      }
      
      self.add_callback(:layouted) {
        view.push_focus(:menu)
      }
    }
  end

  def decided(control, index, x, y)
    child = control && control.child_at(index)
    on_item_selected(index, *child.item.data) if child
  end
  
  def canceled(control, index)
    on_canceled
  end


  # --------------------------------------------------
  # Sceneの中でLayout::Viewを動作させる実装
  # 

  def initialize(manager, *args, &block)
    if CursorIndex === args[0]
      cursor_index = args[0].to_i
      super(manager, *args.drop(1), &block)
      @args = args
    else
      super
      @args = CursorIndex.new(0), *args
    end
    @block = block
    @viewmodel = viewmodel_klass.new
    focus.activate
    root_control.debug = false
    setup_layout
    control(:menu).cursor_index = cursor_index if cursor_index
  end
  
  def finalize
    super
    @args[0].update(control(:menu).cursor_index)
    finalize_layout
  end
  
  def update
    super
    if alive?
      if focus.empty?
        quit
      else
        update_layout
      end
    end
  end
  
  def draw
    super
    if alive?
      draw_layout
    end
  end

end
