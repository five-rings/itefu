=begin
  Layoutシステム /選択した項目にカーソルを表示する
  @note Control::Compositeにmix-inして使用する
=end
module Itefu::Layout::Control::Cursor
  include Itefu::Layout::Control::Selector

  def self.extended(object)
    super
    Itefu::Layout::Control::Selector.extended(object)
  end
  
  def parent_window
    render_target && render_target.recent_ancestor(Itefu::Layout::Control::Window)
  end
  
  def on_active_effect(index)
    # 選択されたコントロールにあわせてカーソルを表示したいが、
    # この後のarrangeで場所がかわるかもしれないので、後にまわす
    @cursor_changed = index
    @cursored_index = index
    super
  end
  
  def arrange(fina_x, final_y, final_w, final_h)
    super
    if @cursored_index && focused?
      @cursor_changed = @cursored_index
    end
  end
  
  def draw
    # Windowにカーソルを表示する
    if index = @cursor_changed
      @cursor_changed = nil
    
      if target = parent_window
        target.window.active = true
        if child = child_at(index)
          # ウィンドウのカーソルを設定
          target.cursor_rect = Box::TEMP.set(
            Utility::Math.max(child.screen_y, self.screen_y),
            Utility::Math.min(child.screen_x + child.actual_width, self.screen_x + self.actual_width),
            Utility::Math.min(child.screen_y + child.actual_height, self.screen_y + self.actual_height),
            Utility::Math.max(child.screen_x, self.screen_x)
          )
        end
      end
    end
    
    # @note 子より先に処理する
    # @note 子の後に処理すると、子がカーソル設定したあと、親が上書きしてしまうことがある
    super
  end
  
  def on_suspend_effect(index)
    if target = parent_window
      target.window.active = false
    end
    super
  end
  
  def on_deactive_effect(index)
    if target = parent_window
      target.cursor_rect = nil
    end
    super
  end
  
end
