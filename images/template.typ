#import "@preview/circuiteria:0.2.0": *

#let flipflop = element.block.with(w: 2, h: 2, ports: (
  west: ((id: "clk", clock: true), (id: "d_in", name: "D")),
  east: ((id: "q_out", name: "Q"),),
))

#let flipflopce = element.block.with(w: 2, h: 2.5, ports: (
  west: ((id: "clk", clock: true), (id: "ce", name: "CE"), (id: "d_in", name: "D")),
  east: ((id: "q_out", name: "Q"),),
))

#let image(body) = {
  set page(
    width: auto,
    height: auto,
    margin: 0pt,
    fill: rgb("#ffffff"),
  )

  body
}
