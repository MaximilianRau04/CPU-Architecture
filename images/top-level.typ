#import "template.typ": *
#show: image

#let color0 = util.colors.blue
#let color1 = util.colors.purple
#let color2 = util.colors.green

#set page(margin: 5pt)

#circuit({
  element.block(
    id: "rom",
    x: -7,
    y: 4.5,
    w: 5,
    h: 2,
    name: "ROM",
    name-anchor: "west",
    ports: (
      east: ((id: "addr", name: "Address"), (id: "instr", name: "Instruction")),
    ),
    fill: util.colors.purple,
  )

  element.block(
    id: "ram",
    x: -7,
    y: 2,
    w: 5,
    h: 2,
    name: "RAM",
    ports: (
      east: (
        (id: "do_read", name: "read"),
        (id: "do_write", name: "write"),
      ),
      west: (
        (id: "addr", name: "addr"),
        (id: "in", name: "in"),
        (id: "out", name: "out"),
      ),
    ),
    fill: util.colors.purple,
  )

  element.block(
    id: "io",
    x: -7,
    y: -0.5,
    w: 5,
    h: 2,
    name: "I/O",
    ports: (
      east: (
        (id: "do_read", name: "read"),
        (id: "do_write", name: "write"),
      ),
      west: (
        (id: "addr", name: "pp"),
        (id: "in", name: "in"),
        (id: "out", name: "out"),
      ),
    ),
    fill: util.colors.pink,
  )

  element.block(
    id: "control",
    x: 0,
    y: 0,
    w: 8,
    h: 6,
    name: "Control Unit",
    fill: util.colors.yellow,
    ports: (
      west: (
        (id: "pc", name: "PC"),
        (id: "instr", name: "Instruction"),
        (id: "mem_read", name: "RAM Read"),
        (id: "mem_write", name: "RAM Write"),
        (id: "io_read", name: "I/O Read"),
        (id: "io_write", name: "I/O Write"),
      ),
      south: (
        (id: "op", name: "op"),
        (id: "sA", name: "sA"),
        (id: "sB", name: "sB"),
        (id: "kk", name: "kk"),
        (id: "carry", name: "C"),
        (id: "zero", name: "Z"),
      ),
      east: (
        (id: "reads_sA", name: "reads_sA"),
        (id: "reads_sB", name: "reads_sB"),
        (id: "use_const", name: "use_const"),
        (id: "write_reg", name: "write_reg"),
        (id: "update_flags", name: "update_flags"),
      ),
      north: (
        (id: "stall", name: "stall"),
        (id: "sA2", name: "sA"),
        (id: "sB2", name: "sB"),
      ),
    ),
  )

  wire.wire("rom:addr", ("control-port-pc", "rom-port-addr"), directed: true, style: "zigzag", zigzag-ratio: 33%)
  wire.wire("rom:instr", ("rom-port-instr", "control-port-instr"), directed: true, style: "zigzag", zigzag-ratio: 33%)

  wire.wire(
    "ram:read",
    ("control-port-mem_read", "ram-port-do_read"),
    directed: true,
    style: "zigzag",
    zigzag-ratio: 50%,
    color: util.colors.purple,
  )
  wire.wire(
    "ram:write",
    ("control-port-mem_write", "ram-port-do_write"),
    directed: true,
    style: "zigzag",
    zigzag-ratio: 100%,
  )

  wire.wire(
    "io:read",
    ("control-port-io_read", "io-port-do_read"),
    directed: true,
    style: "zigzag",
    zigzag-ratio: 66%,
    color: util.colors.pink,
  )
  wire.wire(
    "io:write",
    ("control-port-io_write", "io-port-do_write"),
    directed: true,
    style: "zigzag",
    zigzag-ratio: 25%,
  )

  element.block(
    id: "data",
    x: 0,
    y: -7,
    w: 8,
    h: 5,
    name: "Datapath",
    fill: util.colors.green,
    ports: (
      west: (
        (id: "use_data_in", name: "use_data_in"),
        (id: "data_in", name: "data_in"),
        (id: "data_out", name: "data_out"),
        (id: "addr_out", name: "addr_out"),
      ),
      north: (
        (id: "op", name: "op"),
        (id: "sA", name: "sA"),
        (id: "sB", name: "sB"),
        (id: "kk", name: "kk"),
        (id: "carry", name: "C"),
        (id: "zero", name: "Z"),
      ),
      east: (
        (id: "update_flags", name: "update_flags"),
        (id: "write_reg", name: "write_reg"),
        (id: "use_const", name: "use_const"),
        (id: "stall", name: "stall"),
      ),
    ),
  )

  wire.wire("op_s", ("control-port-op", "data-port-op"), directed: true, style: "zigzag")
  wire.wire("sA_s", ("control-port-sA", "data-port-sA"), directed: true, style: "zigzag")
  wire.wire("sB_s", ("control-port-sB", "data-port-sB"), directed: true, style: "zigzag")
  wire.wire("kk_s", ("control-port-kk", "data-port-kk"), directed: true, style: "zigzag")
  wire.wire("carry_s", ("data-port-carry", "control-port-carry"), directed: true, style: "zigzag")
  wire.wire("zero_s", ("data-port-zero", "control-port-zero"), directed: true, style: "zigzag")

  wire.wire(
    "update_flags_s",
    ("control-port-update_flags", "data-port-update_flags"),
    directed: true,
    style: "dodge",
    dodge-margins: (.33, -.33),
  )
  wire.wire(
    "write_reg_s",
    ("control-port-write_reg", "data-port-write_reg"),
    directed: true,
    style: "dodge",
    dodge-margins: (.66, -.66),
  )
  wire.wire(
    "use_const_s",
    ("control-port-use_const", "data-port-use_const"),
    directed: true,
    style: "dodge",
    dodge-margins: (1, -1),
  )

  wire.wire(
    "data_out:ram",
    ("data-port-data_out", "ram-port-in"),
    directed: true,
    style: "dodge",
    dodge-y: -5,
    dodge-sides: ("west", "west"),
    dodge-margins: (.66, .66),
  )
  wire.wire(
    "data_out:io",
    ("data-port-data_out", "io-port-in"),
    directed: true,
    style: "dodge",
    dodge-y: -5,
    dodge-sides: ("west", "west"),
    dodge-margins: (.66, .66),
  )
  // ToDo: intersection with data_out:ram

  wire.wire(
    "addr_out:ram",
    ("data-port-addr_out", "ram-port-addr"),
    directed: true,
    style: "dodge",
    dodge-y: -6,
    dodge-sides: ("west", "west"),
    dodge-margins: (1, 1),
  )
  wire.wire(
    "addr_out:io",
    ("data-port-addr_out", "io-port-addr"),
    directed: true,
    style: "dodge",
    dodge-y: -6,
    dodge-sides: ("west", "west"),
    dodge-margins: (1, 1),
  )
  // ToDo: intersection with addr_out:ram

  element.gate-or(
    id: "use_data_in_or",
    x: -.6,
    y: -3.4,
    w: .5,
    h: .75,
  )

  wire.wire("use_data_in_s", ("use_data_in_or-port-out", "data-port-use_data_in"), style: "zigzag")

  wire.wire(
    "use_data_in_or:io",
    ("ram:read.zag", "use_data_in_or-port-in0"),
    directed: true,
    style: "zigzag",
    zigzag-ratio: 0%,
    color: util.colors.purple,
  )
  wire.intersection("ram:read.zag", fill: util.colors.purple)

  wire.wire(
    "use_data_in_or:io",
    ("io:read.zag", "use_data_in_or-port-in1"),
    directed: true,
    style: "zigzag",
    zigzag-ratio: 0%,
    color: util.colors.pink,
  )
  wire.intersection("io:read.zag", fill: util.colors.pink)

  element.multiplexer(
    id: "data_in_mux",
    x: -5,
    y: -4.5,
    w: 1,
    h: 2,
  )
  wire.stub("data_in_mux.north", "north", name: "IO / RAM")

  wire.wire(
    "data_in:io",
    ("io-port-out", "data_in_mux-port-in0"),
    directed: true,
    style: "dodge",
    dodge-y: -3,
    dodge-sides: ("west", "west"),
    dodge-margins: (.33, .33),
    color: util.colors.pink,
  )
  wire.wire(
    "data_in:ram",
    ("ram-port-out", "data_in_mux-port-in1"),
    directed: true,
    style: "dodge",
    dodge-y: -4,
    dodge-sides: ("west", "west"),
    dodge-margins: (1.33, 1.33),
    color: util.colors.purple,
  )

  wire.wire(
    "data_in",
    ("data_in_mux-port-out", "data-port-data_in"),
    directed: true,
    style: "zigzag",
  )

  element.block(
    id: "hazard",
    name: [Hazard \ Detection],
    x: 0,
    y: 7,
    w: 8,
    h: 3,
    fill: util.colors.orange,
    ports: (
      east: (
        (id: "stall", name: "stall"),
        (id: "reads_sB", name: "reads_sB"),
        (id: "reads_sA", name: "reads_sA"),
      ),
      south: (
        (id: "stall_control", name: "stall"),
        (id: "sA2", name: "sA"),
        (id: "sB2", name: "sB"),
      ),
    ),
  )

  wire.wire("stall_control", ("hazard-port-stall_control", "control-port-stall"), directed: true)
  wire.wire("hazard:sA", ("control-port-sA2", "hazard-port-sA2"), directed: true)
  wire.wire("hazard:sB", ("control-port-sB2", "hazard-port-sB2"), directed: true)
  wire.wire(
    "stall_data",
    ("hazard-port-stall", "data-port-stall"),
    directed: true,
    style: "dodge",
    dodge-margins: (1.33, -1.33),
  )

  wire.wire(
    "reads_sA_hazard",
    ("control-port-reads_sA", "hazard-port-reads_sA"),
    directed: true,
    style: "dodge",
    dodge-margins: (.33, -.33),
    dodge-y: 5,
  )
  wire.wire(
    "reads_sB_hazard",
    ("control-port-reads_sB", "hazard-port-reads_sB"),
    directed: true,
    style: "dodge",
    dodge-margins: (.66, -.66),
    dodge-y: 5,
  )
})
