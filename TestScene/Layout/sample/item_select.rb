=begin
  項目選択のテスト
=end

if debug?
  DummyData = Struct.new(:menu_items)
  MenuItem = Struct.new(:label)
  context = DummyData.new([])
  context.menu_items.push MenuItem.new("Back")
  context.menu_items.push MenuItem.new("Save/Load")
  context.menu_items.push nil
  context.menu_items.push MenuItem.new("Status")
  context.menu_items.push MenuItem.new("Equip")
  context.menu_items.push MenuItem.new("Item")
  context.menu_items.push MenuItem.new("Config")
end

_(Window, 640, 480) {
  extend Scrollable
  attribute width: 1.0,
            scroll_x: 50,
            height: 1.0

  @scroll = 50
  add_callback(:update) {
    self.scroll_x = @scroll
    @scroll -= 1 if @scroll > 0
  }

_(Lineup) {
  extend Background
  extend Cursor
  attribute name: :select,
            orientation: Orientation::VERTICAL,
            horizontal_alignment: Alignment::CENTER,
            vertical_alignment: Alignment::TOP,
            background: const_color(0xff, 0, 0, 0x3f),
            margin: box(4),
            width: 0.5, height: 1.0

  _(Lineup) {
   # extend SpriteTarget
    extend Background
    extend Cursor
#    extend Scrollable
    extend Pagable
    attribute page_size: 2, page_count: 0
    attribute background: const_color(0, 0, 0, 0x7f)
    attribute name: :select2,
              orientation: Orientation::VERTICAL,
              vertical_alignment: Alignment::TOP,
              horizontal_alignment: Alignment::CENTER,
              width: 160,
              height: Size::AUTO,
              max_height: 100,
              padding: box(5),
              items: binding { context.menu_items },
              item_template: proc {|item|
      if item
        _(Label) {
          attribute text: item.label, padding: box(1,5,1,10)
        }
      else
        _(Unselectable, Separator) {
          attribute height: 3, margin: const_box(5,1), padding: const_box(1), border_color: Color.Black, separate_color: Color.Red
        }
      end
              }

      _(Label) {
        attribute width: Size::AUTO, max_width: 1.0,
                  font_size: 12+rand(5)*4,
                  text: "Additional Information",
                  item_index: nil,
                  horizontal_alignment: Alignment::RIGHT
      }

  }
  _(Lineup) {
 #   extend SpriteTarget
    extend Cursor
    extend Background
  #  attribute contents_creation: ContentsCreation::IF_LARGE
    attribute orientation: Orientation::HORIZONTAL,
              background: const_color(0, 0, 0xff, 0x3f),
              width: 120, height: -20
    _(Label) {
      attribute text: "OK", width: 60, horizontal_alignment: Alignment::CENTER
      add_callback(:drawn_control) {
        $stderr.puts "OK drawn"
      }
    }
    _(Label) {
      attribute text: "CANCEL", width: 60, horizontal_alignment: Alignment::CENTER
    }
  }
}
}

self.add_callback(:layouted) {
  view.push_focus(:select)
}

