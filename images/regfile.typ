#import "template.typ": *
#show: image

#let color0 = util.colors.blue
#let color1 = util.colors.purple
#let color2 = util.colors.green

#circuit({
  element.group(
    {
      element.block(
        id: "decoder",
        x: -5,
        y: 8,
        w: 3,
        h: 2,
        name: "Decoder",
        fill: util.colors.orange,
        ports: (
          north: ((id: "addr_write_in", name: "address"),),
          south: ((id: "reg_0", name: "2"), (id: "reg_1", name: "1"), (id: "reg_2", name: "0")),
        ),
      )

      wire.stub("decoder-port-addr_write_in", "north", name: "Write Addr")

      element.gate-and(id: "decoder_and_0", x: -1.5, y: 1, w: .5, h: .5)
      element.gate-and(id: "decoder_and_1", x: -1.5, y: 4, w: .5, h: .5)
      element.gate-and(id: "decoder_and_2", x: -1.5, y: 7, w: .5, h: .5)

      wire.wire(
        "decoder_and_0",
        ("decoder-port-reg_0", "decoder_and_0-port-in0"),
        style: "zigzag",
        zigzag-ratio: 0%,
        color: color0,
      )
      wire.wire(
        "decoder_and_1",
        ("decoder-port-reg_1", "decoder_and_1-port-in0"),
        style: "zigzag",
        zigzag-ratio: 0%,
        color: color1,
      )
      wire.wire(
        "decoder_and_2",
        ("decoder-port-reg_2", "decoder_and_2-port-in0"),
        style: "zigzag",
        zigzag-ratio: 0%,
        color: color2,
      )

      wire.wire(
        "decoder_and_0_2",
        ((-2, 0), "decoder_and_0-port-in1"),
        style: "zigzag",
        zigzag-ratio: 0%
      )
      wire.wire(
        "decoder_and_1_2",
        ("decoder_and_0_2.zig", "decoder_and_1-port-in1"),
        style: "zigzag",
        zigzag-ratio: 0%
      )
      wire.intersection("decoder_and_0_2.zag")
      wire.wire(
        "decoder_and_2_2",
        ("decoder_and_1_2.zig", "decoder_and_2-port-in1"),
        style: "zigzag",
        zigzag-ratio: 0%
      )
      wire.intersection("decoder_and_1_2.zag")

      wire.stub("decoder_and_0_2.zig", "west", name: "Write Enable", length: 2em)
      wire.intersection("decoder_and_0_2.zig")

      // --- Registers --- //

      flipflopce(id: "reg_0", x: 0, y: 0, name: "2", fill: color0)
      flipflopce(id: "reg_1", x: 0, y: 3, name: "1", fill: color1)
      flipflopce(id: "reg_2", x: 0, y: 6, name: "0", fill: color2)

      wire.wire(
        "decoder_and_0_out",
        ("decoder_and_0-port-out", "reg_0-port-ce"),
        style: "zigzag",
        zigzag-ratio: 100%,
        color: color0,
      )
      wire.wire(
        "decoder_and_1_out",
        ("decoder_and_1-port-out", "reg_1-port-ce"),
        style: "zigzag",
        zigzag-ratio: 100%,
        color: color1,
      )
      wire.wire(
        "decoder_and_2_out",
        ("decoder_and_2-port-out", "reg_2-port-ce"),
        style: "zigzag",
        zigzag-ratio: 100%,
        color: color2,
      )

      wire.wire("reg_0_data_in", ("reg_0-port-d_in", (-0.5, 3.75)), style: "zigzag", zigzag-ratio: 100%)
      wire.wire("reg_1_data_in", ("reg_1-port-d_in", (-0.5, 3.75)), style: "zigzag", zigzag-ratio: 50%)
      wire.wire("reg_2_data_in", ("reg_2-port-d_in", (-0.5, 3.75)), style: "zigzag", zigzag-ratio: 100%)
      wire.stub("reg_0_data_in.zag", "west", name: "data", length: 9em)

      wire.intersection("reg_0_data_in.zag")

      // --- B --- //

      element.multiplexer(id: "mux_b", x: 3, y: 0, w: 1, h: 3, entries: ("0", "1", "2"), fill: util.colors.orange)

      wire.stub("mux_b.south", "south", name: "sB", length: 2em)

      wire.wire("reg_0_out", ("reg_0-port-q_out", "mux_b-port-in2"), style: "zigzag", zigzag-ratio: 25%, color: color0)
      wire.wire("reg_1_out", ("reg_1-port-q_out", "mux_b-port-in1"), style: "zigzag", zigzag-ratio: 50%, color: color1)
      wire.wire("reg_2_out", ("reg_2-port-q_out", "mux_b-port-in0"), style: "zigzag", zigzag-ratio: 75%, color: color2)

      flipflop(id: "b_reg", x: 5, y: 1.5, name: "B", fill: util.colors.orange)

      wire.wire("mux_b_out", ("mux_b-port-out", "b_reg-port-d_in"), style: "zigzag", zigzag-ratio: 50%)
      wire.stub("b_reg-port-q_out", "east", name: "(sB)")

      // --- A --- //

      element.multiplexer(id: "mux_a", x: 3, y: 6, w: 1, h: 3, entries: ("0", "1", "2"), fill: util.colors.orange)

      wire.stub("mux_a.north", "north", name: "sA", length: 2em)

      wire.wire("reg_0_out", ("reg_0-port-q_out", "mux_a-port-in2"), style: "zigzag", zigzag-ratio: 25%, color: color0)
      wire.wire("reg_1_out", ("reg_1-port-q_out", "mux_a-port-in1"), style: "zigzag", zigzag-ratio: 50%, color: color1)
      wire.wire("reg_2_out", ("reg_2-port-q_out", "mux_a-port-in0"), style: "zigzag", zigzag-ratio: 75%, color: color2)

      wire.intersection("reg_0_out.zig", fill: color0)
      wire.intersection("reg_1_out.zig", fill: color1)
      wire.intersection("reg_2_out.zig", fill: color2)

      flipflop(id: "a_reg", x: 5, y: 5.5, name: "A", fill: util.colors.orange)

      wire.wire("mux_a_out", ("mux_a-port-out", "a_reg-port-d_in"), style: "zigzag", zigzag-ratio: 50%)
      wire.stub("a_reg-port-q_out", "east", name: "(sA)")
    },
    name: "Registerfile",
    stroke: (dash: "dashed"),
  )
})
