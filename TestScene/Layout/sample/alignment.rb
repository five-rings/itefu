=begin
  Alignmentのテスト
=end

_(Canvas) {
  extend Drawable
  extend Background
  attribute width: 1.0, height: 1.0,
            background: Color.White

  # Top Left
  _(Canvas) {
    extend Drawable
    extend Background
    attribute width: 160, height: 160,
              background: Color.Black,
              margin: box(1, 1),
              padding: box(10),
              horizontal_alignment: Alignment::LEFT,
              vertical_alignment: Alignment::TOP
    _(Separator) { attribute width: 8, height: 8, separate_color: Color.Red }
    _(Separator) { attribute width: 8, height: 8, margin: box(10, 100, 100, 10), separate_color: Color.Red }
    _(Separator) { attribute width: 8, height: 8, margin: box(20), padding: box(2), separate_color: Color.Red }
  }

  # Top Center
  _(Canvas) {
    extend Drawable
    extend Background
    attribute width: 160, height: 160,
              background: Color.Black,
              margin: box(1, 162),
              padding: box(10),
              horizontal_alignment: Alignment::CENTER,
              vertical_alignment: Alignment::TOP
    _(Separator) { attribute width: 8, height: 8, separate_color: Color.Red }
    _(Separator) { attribute width: 8, height: 8, margin: box(10, 35, 100,  5), separate_color: Color.Blue }
    _(Separator) { attribute width: 8, height: 8, margin: box(10,  5, 100, 35), separate_color: Color.Green }
    _(Separator) { attribute width: 8, height: 8, margin: box(10, 35, 100, 35), separate_color: Color.Red }
    _(Separator) { attribute width: 8, height: 8, margin: box(20, 0, 100, 0), padding: box(2), separate_color: Color.Red }
  }
  
  # Top Right
  _(Canvas) {
    extend Drawable
    extend Background
    attribute width: 160, height: 160,
              background: Color.Black,
              margin: box(1, 323),
              padding: box(10),
              horizontal_alignment: Alignment::RIGHT,
              vertical_alignment: Alignment::TOP
    _(Separator) { attribute width: 8, height: 8, separate_color: Color.Red }
    _(Separator) { attribute width: 8, height: 8, margin: box(10, 10, 100, 100), separate_color: Color.Red }
    _(Separator) { attribute width: 8, height: 8, margin: box(20), padding: box(2), separate_color: Color.Red }
  }

  # Center Left
  _(Canvas) {
    extend Drawable
    extend Background
    attribute width: 160, height: 160,
              background: Color.Black,
              margin: box(162, 1),
              padding: box(10),
              horizontal_alignment: Alignment::LEFT,
              vertical_alignment: Alignment::CENTER
    _(Separator) { attribute width: 8, height: 8, separate_color: Color.Red }
    _(Separator) { attribute width: 8, height: 8, margin: box(100, 10), separate_color: Color.Red }
    _(Separator) { attribute width: 8, height: 8, margin: box(35, 10,  5, 10), separate_color: Color.Blue }
    _(Separator) { attribute width: 8, height: 8, margin: box( 5, 10, 35, 10), separate_color: Color.Green }
    _(Separator) { attribute width: 8, height: 8, margin: box(20), padding: box(2), separate_color: Color.Red }
  }

  # Center Center
  _(Canvas) {
    extend Drawable
    extend Background
    attribute width: 160, height: 160,
              background: Color.Black,
              margin: box(162, 162),
              padding: box(10),
              horizontal_alignment: Alignment::CENTER,
              vertical_alignment: Alignment::CENTER
    _(Separator) { attribute width: 8, height: 8, separate_color: Color.Red }
    _(Separator) { attribute width: 8, height: 8, padding: box(1), separate_color: Color.Black }
    _(Separator) { attribute width: 8, height: 8, padding: box(2,3,3,2), separate_color: Color.White }
    _(Separator) { attribute width: 8, height: 8, margin: box(35, 10,  5, 10), separate_color: Color.Blue }
    _(Separator) { attribute width: 8, height: 8, margin: box( 5, 10, 35, 10), separate_color: Color.Green }
    _(Separator) { attribute width: 8, height: 8, margin: box(10, 35, 10,  5), separate_color: Color.Blue }
    _(Separator) { attribute width: 8, height: 8, margin: box(10,  5, 10, 35), separate_color: Color.Green }
  }

  # Center Right
  _(Canvas) {
    extend Drawable
    extend Background
    attribute width: 160, height: 160,
              background: Color.Black,
              margin: box(162, 323),
              padding: box(10),
              horizontal_alignment: Alignment::RIGHT,
              vertical_alignment: Alignment::CENTER
    _(Separator) { attribute width: 8, height: 8, separate_color: Color.Red }
    _(Separator) { attribute width: 8, height: 8, margin: box(100, 10), separate_color: Color.Red }
    _(Separator) { attribute width: 8, height: 8, margin: box(35, 10,  5, 10), separate_color: Color.Blue }
    _(Separator) { attribute width: 8, height: 8, margin: box( 5, 10, 35, 10), separate_color: Color.Green }
    _(Separator) { attribute width: 8, height: 8, margin: box(20), padding: box(2), separate_color: Color.Red }
  }

  # Bottm Left
  _(Canvas) {
    extend Drawable
    extend Background
    attribute width: 160, height: 160,
              background: Color.Black,
              margin: box(323, 1),
              padding: box(10),
              horizontal_alignment: Alignment::LEFT,
              vertical_alignment: Alignment::BOTTOM
    _(Separator) { attribute width: 8, height: 8, separate_color: Color.Red }
    _(Separator) { attribute width: 8, height: 8, margin: box(100, 100, 10, 10), separate_color: Color.Red }
    _(Separator) { attribute width: 8, height: 8, margin: box(20), padding: box(2), separate_color: Color.Red }
  }

  # Bottm Center
  _(Canvas) {
    extend Drawable
    extend Background
    attribute width: 160, height: 160,
              background: Color.Black,
              margin: box(323, 162),
              padding: box(10),
              horizontal_alignment: Alignment::CENTER,
              vertical_alignment: Alignment::BOTTOM
    _(Separator) { attribute width: 8, height: 8, separate_color: Color.Red }
    _(Separator) { attribute width: 8, height: 8, margin: box(100, 35, 10,  5), separate_color: Color.Blue }
    _(Separator) { attribute width: 8, height: 8, margin: box(100,  5, 10, 35), separate_color: Color.Green }
    _(Separator) { attribute width: 8, height: 8, margin: box(100, 35, 10, 35), separate_color: Color.Red }
    _(Separator) { attribute width: 8, height: 8, margin: box(100,  0, 20, 0), padding: box(2), separate_color: Color.Red }
  }
  
  # Bottom Right
  _(Canvas) {
    extend Drawable
    extend Background
    attribute width: 160, height: 160,
              background: Color.Black,
              margin: box(323, 323),
              padding: box(10),
              horizontal_alignment: Alignment::RIGHT,
              vertical_alignment: Alignment::BOTTOM
    _(Separator) { attribute width: 8, height: 8, separate_color: Color.Red }
    _(Separator) { attribute width: 8, height: 8, margin: box(100, 10, 10, 100), separate_color: Color.Red }
    _(Separator) { attribute width: 8, height: 8, margin: box(20), padding: box(2), separate_color: Color.Red }
  }
}

