

_(Window, 640, 480) {
  attribute width: 1.0, height: 1.0

  _(Grid) {
    extend Selector
    add_row_separator 0.5
    attribute name: :menu

    _(Grid) {
      extend Cursor 
      add_col_separator 0.5
      attribute grid_row: 1, grid_col: 0,
                horizontal_alignment: Alignment::CENTER,
                vertical_alignment: Alignment::CENTER

      _(Label) {
        attribute grid_row: 0, grid_col: 1,
                  padding: const_box(5),
                  text: "Bottom"
      }
      _(Label) {
        attribute grid_row: 0, grid_col: 0,
                  padding: const_box(5),
                  text: "Top"
      }
    }

    _(Grid) {
      extend Cursor 
      add_row_separator 0.25, 0.5
      add_col_separator 0.5
      attribute grid_row: 0, grid_col: 0,
                padding: box(10),
                horizontal_alignment: Alignment::STRETCH,
                vertical_alignment: Alignment::STRETCH

      _(Label) {
        extend Background
        attribute background: Color.DarkRed,
                  grid_row: 0, grid_col: 0,
                  margin: const_box(10),
                  padding: const_box(5),
                  horizontal_alignment: Alignment::CENTER,
                  vertical_alignment: Alignment::CENTER,
                  text: "0,0"
      }
      _(Label) {
        extend Background
        attribute grid_row: 0, grid_col: 1,
                  padding: const_box(5),
                  background: Color.DarkGoldenRod,
                  horizontal_alignment: Alignment::CENTER,
                  vertical_alignment: Alignment::CENTER,
                  text: "0,1"
      }
      _(Label) {
        extend Background
        attribute grid_row: 1, grid_col: 0,
                  padding: const_box(5),
                  background: Color.DarkGreen,
                  horizontal_alignment: Alignment::CENTER,
                  vertical_alignment: Alignment::CENTER,
                  text: "1,0"
      }
      _(Label) {
        extend Background
        attribute grid_row: 1, grid_col: 1,
                  padding: const_box(5),
                  background: Color.DarkBlue,
                  horizontal_alignment: Alignment::CENTER,
                  vertical_alignment: Alignment::CENTER,
                  text: "1,1"
      }
      _(Label) {
        extend Background
        attribute grid_row: 2, grid_col: 0,
                  padding: const_box(5),
                  background: Color.DarkMagenta,
                  horizontal_alignment: Alignment::CENTER,
                  vertical_alignment: Alignment::CENTER,
                  text: "2,0"
      }
      _(Label) {
        extend Background
        attribute grid_row: 2, grid_col: 1,
                  padding: const_box(5),
                  background: Color.DarkViolet,
                  horizontal_alignment: Alignment::CENTER,
                  vertical_alignment: Alignment::CENTER,
                  text: "2,1"
      }
    }
  }
}

self.add_callback(:layouted) {
  view.push_focus(:menu)
}

