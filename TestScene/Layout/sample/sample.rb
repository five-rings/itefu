=begin
  実装テスト用のサンプルレイアウト
=end

type = 3

case type
when 1

  _(Sprite, 120, 120) {
    extend Background
    attribute width: 120, height: 120,
              margin: const_box(50, 0, 0, 10),
              background: bg_image("Graphics/Titles1/Book", true, nil, nil, nil),
              padding: const_box(5)

    _(Label) {
      extend Background
      attribute text: "aiueo13869",
                width: 1.0, height: 0.5,
                font_size: 20,
                horizontal_alignment: Alignment::RIGHT,
                vertical_alignment: Alignment::BOTTOM,
                font_name: "Georgia",
                margin: const_box(2),
                background: const_color(0x7f, 0, 0x24, 0x7f),
                independent: true
    }
  }

when 2

  _(Sprite, 0, 0) {
#    extend Background
    attribute width: 200, height: 200,
              margin: const_box(50, 0, 0, 10),
#              background: bg_image("Graphics/Titles1/Book", true, nil, nil, nil),
#              horizontal_alignment: Alignment::STRETCH,
#              vertical_alignment: Alignment::STRETCH,
              padding: box(5)
    _(Image) {
      attribute image_source: image("Graphics/Titles1/Fountain"),
                width: 1.0, height: 1.0,
                source_rect: const_rect(100, 100, -100, -100)
    }
  }

when 3

  _(Sprite, 0, 0) {
    attribute width: 200, height: 200,
              margin: const_box(50, 0, 0, 10),
              padding: box(5)
    _(Face) {
      attribute image_source: image("Actor1"),
                width: 1.0, height: 1.0,
                vertical_alignment: Alignment::STRETCH,
                horizontal_alignment: Alignment::STRETCH,
                face_index: 1
    }
  }

when 4

  _(Sprite, 0, 0) {
    extend Background
    attribute width: 200, height: 200,
              background: bg_image("Graphics/Titles1/Book", true),
              margin: const_box(50, 0, 0, 10),
              padding: box(5)
    _(Chara) {
      attribute image_source: image("Actor1"),
#                independent: true,
                chara_direction: Direction::LEFT,
                chara_index: 1
    }
  }

when 5

  _(Sprite, 0, 0) {
    extend Background
    attribute width: 200, height: 200,
              background: bg_image("Graphics/Titles1/Book", true),
              margin: const_box(50, 0, 0, 10),
              padding: box(5)
    _(Icon) {
      extend Background
      attribute icon_index: 12,
                margin: box(10),
                background: const_color(0, 0, 0, 0x7f)
    }
    _(Separator) {
      attribute width: 1.0, height: 3,
                margin: box(10),
                padding: box(1),
                separate_color: Color.White,
                border_color: Color.Black
    } if false
  }

end


