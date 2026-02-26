#import "template.typ": *
#show: image

#let modes = (
  all: "all",
  alu-only: "alu-only",
  writeback-only: "writeback-only"
)
#let mode = modes.alu-only

#circuit({
  flipflop(id: "addr_write_delay1_reg", x: -3, y: 1, fill: if mode != modes.alu-only { util.colors.orange })

  wire.wire("addr_write_delay1_s", ((-4, 4.3), "addr_write_delay1_reg-port-d_in"), style: "zigzag", zigzag-ratio: 0%)
  wire.intersection("addr_write_delay1_s.zig")

  flipflop(id: "do_write_delay1_reg", x: -3, y: -1.5, fill: if mode != modes.alu-only { util.colors.orange })

  wire.stub("do_write_delay1_reg-port-d_in", "west", name: "do_write")

  element.block(x: 0, y: 1, w: 5, h: 4, id: "regfile", name: "Registers", fill: util.colors.orange, ports: (
    north: ((id: "clk", clock: true),),
    west: (
      (id: "addrA_in", name: "sA"),
      (id: "addrB_in", name: "sB"),
      (id: "data_in", name: "data"),
      (id: "addr_write_in", name: "Write Addr"),
      (id: "do_write_in", name: "Write Enable"),
    ),
    east: ((id: "A_out", name: "(sA)"), (id: "B_out", name: "(sB)")),
  ))

  wire.stub("regfile-port-addrA_in", "west", name: "sA", length: 9em)
  wire.stub("regfile-port-addrB_in", "west", name: "sB", length: 9em)

  wire.wire("addr_write_delay1_s", ("addr_write_delay1_reg-port-q_out", "regfile-port-addr_write_in"), style: "zigzag")
  wire.wire("do_write_delay1_s", ("do_write_delay1_reg-port-q_out", "regfile-port-do_write_in"), style: "zigzag")

  element.block(x: 10, y: 0, w: 4, h: 6, id: "alu", name: "ALU", fill: if mode != modes.writeback-only { util.colors.yellow }, ports: (
    west: (
      (id: "op_in", name: "OP"),
      (id: "A_in", name: "(sA)"),
      (id: "B_in", name: "(sB)"),
      (id: "z_in", name: "Zero"),
      (id: "c_in", name: "Carry"),
    ),
    east: ((id: "result_out", name: "Result"), (id: "zero_out", name: "Zero"), (id: "carry_out", name: "Carry")),
  ))

  element.multiplexer(x: 6, y: 0, w: 1, h: 3, id: "b_mux", entries: ("(sB)", "kk"), fill: if mode != modes.writeback-only { util.colors.yellow })

  flipflop(x: 0, y: -3, id: "const_delay1_reg", fill: if mode != modes.writeback-only { util.colors.orange })

  wire.stub("const_delay1_reg-port-d_in", "west", name: "kk", length: 7em)

  flipflop(x: 2, y: -5, id: "use_const_delay1_reg", fill: if mode != modes.writeback-only { util.colors.orange })

  wire.stub("use_const_delay1_reg-port-d_in", "west", name: "use_const", length: 11em)

  wire.wire("A", ("regfile-port-A_out", "alu-port-A_in"), style: "zigzag")
  wire.wire("B", ("regfile-port-B_out", "b_mux-port-in0"), style: "zigzag")
  wire.wire("B_alu", ("b_mux-port-out", "alu-port-B_in"), style: "zigzag")
  wire.wire("const_delay_1_s", ("const_delay1_reg-port-q_out", "b_mux-port-in1"), style: "zigzag")
  wire.wire(
    "use_const_delay_1_s",
    ("use_const_delay1_reg-port-q_out", "b_mux.south"),
    style: "zigzag",
    zigzag-ratio: 100%,
  )

  flipflop(id: "use_data_delay1_reg", x: 0, y: 8, fill: if mode != modes.alu-only { util.colors.orange })

  wire.stub("use_data_delay1_reg-port-d_in", "west", name: "use_data_in", length: 7em)

  flipflop(id: "alu_op_delay1_reg", x: 2, y: 6, fill: if mode != modes.writeback-only { util.colors.orange })

  wire.stub("alu_op_delay1_reg-port-d_in", "west", name: "alu_op", length: 11em)

  element.multiplexer(x: 16.5, y: 3, w: 1, h: 3, id: "writeback_mux", entries: 2, fill: if mode != modes.alu-only { util.colors.yellow })

  wire.wire(
    "data_in",
    ((15, 11), "writeback_mux-port-in0"),
    style: "zigzag",
    name: "data_in",
    name-pos: "start",
    zigzag-ratio: 0%,
  )
  wire.wire("alu_result", ("alu-port-result_out", "writeback_mux-port-in1"), style: "zigzag")
  wire.wire("data_in", ("use_data_delay1_reg-port-q_out", "writeback_mux.north"), style: "zigzag", zigzag-ratio: 100%)
  wire.wire("writeback", ("writeback_mux-port-out", "regfile-port-data_in"), style: "dodge", dodge-y: 10.5)

  flipflop(id: "carry_reg", x: 16, y: -2, fill: if mode != modes.writeback-only { util.colors.orange })

  wire.wire("carry_s", ("alu-port-carry_out", "carry_reg-port-d_in"), style: "zigzag", zigzag-ratio: 25%)
  wire.wire("carry_reg_fb", ("carry_reg-port-q_out", "alu-port-c_in"), style: "dodge", dodge-y: -2.5)

  flipflop(id: "zero_reg", x: 16, y: 0.5, fill: if mode != modes.writeback-only { util.colors.orange })

  wire.stub("carry_s.zag", "south", length: 7em, name: "Carry")
  wire.intersection("carry_s.zag")

  wire.wire("zero_s", ("alu-port-zero_out", "zero_reg-port-d_in"), style: "zigzag", zigzag-ratio: 75%)
  wire.wire(
    "zero_reg_fb",
    ("zero_reg-port-q_out", "alu-port-z_in"),
    style: "dodge",
    dodge-y: -3.5,
    dodge-margins: (1, 1),
  )

  wire.stub("zero_s.zag", "south", length: 14em, name: "Zero")
  wire.intersection("zero_s.zag")

  wire.wire("alu_op_delay1_s", ("alu_op_delay1_reg-port-q_out", "alu-port-op_in"), style: "zigzag")

  wire.wire("address_out", ((8.5, 1.5), (8.5, -6)), style: "zigzag", name: "address_out", name-pos: "end")
  wire.intersection("address_out.zig")

  wire.wire("data_out", ((7.5, 3.6), (7.5, -5)), style: "zigzag", name: "data_out", name-pos: "end")
  wire.intersection("data_out.zig")
})