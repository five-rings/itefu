=begin
  レイアウトをプレビューする  
=end
class Itefu::TestScene::Layout::Preview < Itefu::Scene::Base
  include Itefu::Layout::View::TextFile
  include Itefu::Layout::View::Effect
  include Itefu::Layout::View::Debug

  def on_initialize(path, filename)
    @focused = false
    self.layout_path = path
    load_layout(File.join(
      File.dirname(filename),
      File.basename(filename, ".#{LAYOUT_EXTENSION}")
    ))
    focus.activate
  rescue RGSSReset
    raise
  rescue Exception => exception
    Itefu::Debug::Dump.show_blank
    Itefu::Debug::Dump.show_stacktrace(exception.backtrace.reverse)
    Itefu::Debug::Dump.show_blank
    Itefu::Debug::Dump.show_exception(exception)
    Itefu::Debug::Dump.show_blank
    quit
  end

  def on_finalize
    finalize_layout
  end

  def on_update
    @focused = true unless focus.empty?
    if @focused
      quit if focus.empty?
    else
      case
      when Itefu::Input::Win32.press_key?(Itefu::Input::Win32::Code::VK_ESCAPE),
           Itefu::Input::Win32.press_key?(Itefu::Input::Win32::Code::VK_RBUTTON)
        quit
      end
    end
    update_layout
  end

  def on_draw
    draw_layout
  end

end
