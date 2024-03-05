
if debug?
  DebugContext = Struct.new(:items)
  context = DebugContext.new([])
  Data = Struct.new(:name)
  context.items.push Data.new("あいうえお")
  context.items.push Data.new("かきくけこ")
  context.items.push Data.new("さしすせそ")
  context.items.push Data.new("たちつてと")
  context.items.push Data.new("なにぬねの")
  context.items.push Data.new("はひふへほ")
  context.items.push Data.new("まみむめも")
end

_(Window, 640, 480) {
  attribute width: 640, height: 480,
            horizontal_alignment: Alignment::CENTER

  _(Lineup) {
    extend Selector
    attribute name: :select_base,
              width: 320, height: 480,
              orientation: Orientation::VERTICAL,
              vertical_alignment: Alignment::TOP,
              horizontal_alignment: Alignment::LEFT

    _(Cabinet) {
      extend Background
      extend Cursor
      attribute name: :select,
                background: const_color(0xff, 0, 0, 0x3f),
                width: 1.0, height: Size::AUTO,
                orientation: Orientation::HORIZONTAL,
                vertical_alignment: Alignment::TOP,
                horizontal_alignment: Alignment::CENTER,
                content_alignment: Alignment::BOTTOM,
                items: binding { context.items },
                item_template: proc {|item, item_index|
        _(Label) {
          attribute text: item.name,
                    font_size: 20
        }
                }
    }
    _(Lineup) {
      extend Cursor
      extend Background
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

self.add_callback(:layouted) do
  view.push_focus(:select_base)
end
