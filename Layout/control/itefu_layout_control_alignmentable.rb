=begin
  Layoutシステム/内容をアラインメントできるコントロールにmix-inする
=end
module Itefu::Layout::Control::Alignmentable
  include Itefu::Layout::Definition
  extend Itefu::Layout::Control::Bindable::Extension
  attr_bindable :horizontal_alignment
  attr_bindable :vertical_alignment
  
  def default_horizontal_alignment; Alignment::LEFT;  end
  def default_vertical_alignment;   Alignment::TOP;   end
 
  # 一時的に作成した領域の中で整列をさせたいとき用のボクシングクラス
  class DummyContent
    attr_accessor :content_left,
                  :content_width,
                  :content_top,
                  :content_height
    def content_right; content_left + content_width; end
    def content_bottom; content_top + content_height; end
    def offset_from_left; 0; end
    def offset_from_top; 0; end
    def offset_from_right; @content_width; end
    def offset_from_bottom; @content_height; end
  end
  DummyContent.const_set(:TEMP, DummyContent.new)

  def initialize(*args)
    super
    self.horizontal_alignment = default_horizontal_alignment
    self.vertical_alignment   = default_vertical_alignment
  end
  
  module AlignmentMethod
    include Itefu::Layout::Definition

    # 子要素の横位置
    def pos_x_alignmented(control, content, halign)
      case halign
      when Alignment::LEFT, Alignment::STRETCH
        control.content_left + content.offset_from_left
      when Alignment::RIGHT
        control.content_right - content.offset_from_right
      else
        control.content_left +
        ( control.content_width -
          content.offset_from_left -
          content.offset_from_right
        ) / 2 +   # 子のmarginを除いた、余白の半分（左右に振り分けるので）
        content.offset_from_left
      end
    end
    
    # 子要素の縦位置
    def pos_y_alignmented(control, content, valign)
      case valign 
      when Alignment::TOP, Alignment::STRETCH
        control.content_top + content.offset_from_top
      when Alignment::BOTTOM
        control.content_bottom - content.offset_from_bottom
      else
        control.content_top +
        ( control.content_height -
          content.offset_from_top -
          content.offset_from_bottom
        ) / 2 +   # 子のmarginを除いた、余白の半分（上下に振り分けるので）
        content.offset_from_top
      end
    end

    # 枠と内容のサイズから枠内の相対位置を得る
    def pos_xy_alignmented(base, size, align)
      case align
      when Alignment::LEFT, # TOP兼用
           Alignment::STRETCH
        0
      when Alignment::RIGHT # BOTTOM兼用
        base - size
      else
        (base - size) / 2
      end
    end
  end
  include AlignmentMethod
  extend  AlignmentMethod

end
