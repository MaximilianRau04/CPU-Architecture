#let project(
  title: "",
  authors: (),
  body,
) = {
  set page(footer: {
    set text(size: 9pt, fill: gray)
    grid(
      columns: (1fr, 1fr, 1fr),
      align: (left, center, right),
      "Group 2", context counter(page).display("1 / 1", both: true), "RO2",
    )
  })
  set par(
    justify: true,
  )
  set text(
    font: "Inter",
  )

  set heading(numbering: "1.")

  show heading.where(level: 1): set text(size: 28pt, weight: 700)
  show heading.where(level: 2): set text(size: 20pt, weight: 600)
  show heading.where(level: 3): set text(size: 16pt, weight: 600)

  set table(
    align: left,
    stroke: (x, y) => (
      top: if y == 0 { 1pt } else if y == 1 { .5pt } else { 0pt },
      bottom: 1pt,
    ),
  )

  set list(indent: 12pt, marker: (sym.bullet, sym.bullet.stroked))

  set raw(theme: "../syntax/GitHub Light.tmTheme")
  show raw.where(lang: "asm"): set raw(
    syntaxes: "../syntax/picoasm.yaml",
  )
  show raw.where(lang: "vhdl"): set raw(
    syntaxes: "../syntax/vhdl.yaml",
  )

  body
}
