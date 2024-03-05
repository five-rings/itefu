=begin
  Layoutシステム/Viewにデバッグ機能を追加する
=end
module Itefu::Layout::View::Debug

  # デバッグ機能を含んだルートを使用する
  def root_control_klass
    Itefu::Layout::Control::Root::Debug
  end
  
  # 一般的なキー入力を仮に提供する
  def handle_input
    input = $itefu_application.system(Itefu::Input::Manager)
    ITEFU_DEBUG_ASSERT(input)
    status = input.find_status(Itefu::Input::Status::Win32)
    ITEFU_DEBUG_ASSERT(status)

    c = focus.current
    case
    when status.triggered?(Itefu::Input::Win32::Code::VK_RETURN)
      c.operate Itefu::Layout::Definition::Operation::DECIDE
    when status.triggered?(Itefu::Input::Win32::Code::VK_LBUTTON)
      x = status.position_x
      y = status.position_y
      c.operate Itefu::Layout::Definition::Operation::DECIDE, x, y
      @old_input_x = x
      @old_input_y = y
    when status.triggered?(Itefu::Input::Win32::Code::VK_ESCAPE),
         status.triggered?(Itefu::Input::Win32::Code::VK_RBUTTON)
      c.operate Itefu::Layout::Definition::Operation::CANCEL
    when status.repeated?(Itefu::Input::Win32::Code::VK_UP)
      c.operate Itefu::Layout::Definition::Operation::MOVE_UP
    when status.repeated?(Itefu::Input::Win32::Code::VK_DOWN)
      c.operate Itefu::Layout::Definition::Operation::MOVE_DOWN
    when status.repeated?(Itefu::Input::Win32::Code::VK_LEFT)
      c.operate Itefu::Layout::Definition::Operation::MOVE_LEFT
    when status.repeated?(Itefu::Input::Win32::Code::VK_RIGHT)
      c.operate Itefu::Layout::Definition::Operation::MOVE_RIGHT
    else
      x = status.position_x
      y = status.position_y
      @old_input_x ||= x
      @old_input_y ||= y
      if @old_input_x != x || @old_input_y != y
        c.operate Itefu::Layout::Definition::Operation::MOVE_POSITION, x, y
      end
      @old_input_x = x
      @old_input_y = y
      
      begin
        if Itefu::Layout::Control::Scrollable === c
          sy = status.scroll_y
          c.scroll(sy) if sy
        end
      rescue Itefu::Layout::Definition::Exception::NotSupported
      end
    end if c
  end

end
