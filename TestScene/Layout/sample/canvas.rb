=begin
  Canvasのテスト
=end
_(Window, 640, 480) {
  attribute width: 640, height: 480

_(Canvas) {
  extend Drawable
  extend Background
  extend Cursor
  attribute width: 320, height: 240,
            name: :select,
            horizontal_alignment: Alignment::CENTER,
            vertical_alignment: Alignment::BOTTOM,
            background: const_color(0, 0, 0xff, 0x3f),
            margin: box(120, 160)

  _(Label) {
    extend Background
    attribute text: "ボタン",
              margin: box(-20, 40, 60, 40),
              padding: box(20),
              background: Color.White,
              horizontal_alignment: Alignment::CENTER,
              vertical_alignment: Alignment::CENTER,
              font_color: Color.Black,
              font_out_color: Color.Transparent,
              font_size: 30
  }

  _(Face) {
    attribute image_source: image("Actor1"),
              face_index: 1,
              padding: const_box(5),
              horizontal_alignment: Alignment::LEFT,
              vertical_alignment: Alignment::TOP
  }

  _(Label) {
    extend Background
    attribute text: "その2",
              padding: const_box(5),
              background: Color.Red,
              font_color: Color.White,
              font_size: 23
  }
}
}

self.add_callback(:layouted) do
  view.push_focus(:select)
end

