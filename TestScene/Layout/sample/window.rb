=begin
  Windowのテスト
=end

extend Background
attribute background: bg_image("Graphics/Titles1/Book")

_(Window, 0, 0) {
  extend Background
  attribute background: bg_image("Graphics/Titles1/Book", true),
            width: 120, height: 120,
            margin: box(10),
            opacity: 0xaf

  _(Label) {
    attribute text: "aiueo"
  }
}

