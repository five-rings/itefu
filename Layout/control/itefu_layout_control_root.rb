=begin
  Layoutシステム/ルートコントロール
=end
class Itefu::Layout::Control::Root < Itefu::Layout::Control::Decorator
  attr_reader :view
  def debug?; false; end
  def root; self; end
  def parent; end

  def initialize(view)
    @view = view
    super(nil)    # ルートノードは親を持たない
    self.name = :root
  end
  
  def impl_finalize
    super
  end
  
  def load_layout(script, *args)
    view = @view
    context = view.context if view
    debug = debug?
    this = self
    case script
    when Proc
      this.instance_eval(&script)
    else
      this.instance_eval(script, *args)
    end
    disarrange
  end
  
  def import(signature)
    load_layout(@view.signature_to_layout(signature), @view.signature_to_filename(signature))
  end
  
  def rearrange(w = nil, h = nil)
    if @disarranged
      x ||= @arrange_x || 0
      y ||= @arrange_y || 0
      w ||= @arrange_width  || 0
      h ||= @arrange_height || 0
      available_width = w - margin.width
      available_height = h - margin.height
      measure(available_width, available_height)
      arrange(x + offset_from_left, y + offset_from_top, available_width, available_height)
      @disarranged = false
    else
      child.rearrange if child
    end
  end
  
  def disarrange(control = nil)
    @disarranged = true
  end

  def position(x, y)
    @disarranged = true if (x && @arrange_x != x) || (y && @arrange_y != y)
    @arrange_x = x if x
    @arrange_y = y if y
  end

  def size(w, h)
    @disarranged = true if (@arrange_width != w) || (@arrange_hegiht != h)
    @arrange_width  = w
    @arrange_height = h
  end

  # ビューワーなど確認時専用のサイズ設定
  def design_size(w, h); end

end
