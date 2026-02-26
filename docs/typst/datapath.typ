#import "@preview/circuiteria:0.2.0"

The datapath connects the register file with the ALU and handles writeback operations. It executes arithmetic, logic, shift and rotate operations on data stored in registers.

The datapath consists of two main components:
(1) the register file, which holds the 16 general-purpose 8-bit registers (s0 to sF), and
(2) the ALU, which performs the actual computation on the register values.

#figure(
  circuiteria.circuit({
    import circuiteria: *

    let flipflop = element.block.with(
      w: 2,
      h: 2,
      ports: (
        west: (
          (id: "clk", clock: true),
          (id: "d_in", name: "D"),
        ),
        east: (
          (id: "q_out", name: "Q"),
        ),
      ),
    )

    flipflop(
      id: "addr_write_delay1_reg",
      x: -3,
      y: 1,
      fill: util.colors.orange,
    )

    wire.wire("addr_write_delay1_s", ((-4, 4.3), "addr_write_delay1_reg-port-d_in"), style: "zigzag", zigzag-ratio: 0%)
    wire.intersection("addr_write_delay1_s.zig")

    flipflop(
      id: "do_write_delay1_reg",
      x: -3,
      y: -1.5,
      fill: util.colors.orange,
    )

    wire.stub("do_write_delay1_reg-port-d_in", "west", name: "do_write")

    element.block(
      x: 0,
      y: 1,
      w: 5,
      h: 4,
      id: "regfile",
      name: "Registers",
      fill: util.colors.orange,
      ports: (
        north: ((id: "clk", clock: true),),
        west: (
          (id: "addrA_in", name: "sA"),
          (id: "addrB_in", name: "sB"),
          (id: "data_in", name: "data"),
          (id: "addr_write_in", name: "Write Addr"),
          (id: "do_write_in", name: "Write Enable"),
        ),
        east: (
          (id: "A_out", name: "(sA)"),
          (id: "B_out", name: "(sB)"),
        ),
      ),
    )

    wire.stub("regfile-port-addrA_in", "west", name: "sA", length: 9em)
    wire.stub("regfile-port-addrB_in", "west", name: "sB", length: 9em)

    wire.wire(
      "addr_write_delay1_s",
      ("addr_write_delay1_reg-port-q_out", "regfile-port-addr_write_in"),
      style: "zigzag",
    )
    wire.wire("do_write_delay1_s", ("do_write_delay1_reg-port-q_out", "regfile-port-do_write_in"), style: "zigzag")

    element.block(
      x: 10,
      y: 0,
      w: 4,
      h: 6,
      id: "alu",
      name: "ALU",
      fill: util.colors.yellow,
      ports: (
        west: (
          (id: "op_in", name: "OP"),
          (id: "A_in", name: "(sA)"),
          (id: "B_in", name: "(sB)"),
          (id: "z_in", name: "Zero"),
          (id: "c_in", name: "Carry"),
        ),
        east: (
          (id: "result_out", name: "Result"),
          (id: "zero_out", name: "Zero"),
          (id: "carry_out", name: "Carry"),
        ),
      ),
    )

    element.multiplexer(
      x: 6,
      y: 0,
      w: 1,
      h: 3,
      id: "b_mux",
      entries: ("(sB)", "kk"),
      fill: util.colors.yellow,
    )

    flipflop(
      x: 0,
      y: -3,
      id: "const_delay1_reg",
      fill: util.colors.orange,
    )

    wire.stub("const_delay1_reg-port-d_in", "west", name: "kk", length: 7em)

    flipflop(
      x: 2,
      y: -5,
      id: "use_const_delay1_reg",
      fill: util.colors.orange,
    )

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

    flipflop(
      id: "use_data_delay1_reg",
      x: 0,
      y: 8,
      fill: util.colors.orange,
    )

    wire.stub("use_data_delay1_reg-port-d_in", "west", name: "use_data_in", length: 7em)

    flipflop(
      id: "alu_op_delay1_reg",
      x: 2,
      y: 6,
      fill: util.colors.orange,
    )

    wire.stub("alu_op_delay1_reg-port-d_in", "west", name: "alu_op", length: 11em)

    element.multiplexer(
      x: 16.5,
      y: 3,
      w: 1,
      h: 3,
      id: "writeback_mux",
      entries: 2,
      fill: util.colors.yellow,
    )

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
    wire.wire(
      "writeback",
      ("writeback_mux-port-out", "regfile-port-data_in"),
      style: "dodge",
      dodge-y: 10.5,
    )

    flipflop(
      id: "carry_reg",
      x: 16,
      y: -2,
      fill: util.colors.orange,
    )

    wire.wire("carry_s", ("alu-port-carry_out", "carry_reg-port-d_in"), style: "zigzag", zigzag-ratio: 25%)
    wire.wire("carry_reg_fb", ("carry_reg-port-q_out", "alu-port-c_in"), style: "dodge", dodge-y: -2.5)

    flipflop(
      id: "zero_reg",
      x: 16,
      y: 0.5,
      fill: util.colors.orange,
    )

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
  }),
  caption: [
    Simplified Circuit Diagram of the Datapath. \
    Not shown are clock, reset, stall and flush signals as well as the multiplexer controlling whether flags are updated.
  ],
)

The register file provides two read ports and one write port. Both read ports can be accessed simultaneously, allowing the ALU to receive two operands in the same clock cycle.

/*
#table(
  columns: (auto, auto, 1fr),
  table.header("Port", "Direction", "Description"),
  `addrA_in`, "Input", "Address of first register to read",
  `addrB_in`, "Input", "Address of second register to read",
  `addr_write_in`, "Input", "Address of register to write",
  `data_in`, "Input", "Data to write to the register file",
  `do_write_in`, "Input", "Write enable signal",
  `A_out`, "Output", "Value read from register at addrA",
  `B_out`, "Output", "Value read from register at addrB",
)*/

As this processor only implements instructions of the one and two-address format the first operand (sX) will overwritten by the result.

Read operations are registered, meaning the output appears one clock cycle after the address is provided.

=== ALU

The ALU receives two 8-bit operands and produces an 8-bit result along with carry and zero flags. The second operand can come either from the register file or from an immediate constant, controlled by the `use_const_in` signal.

The full list of ALU operations is in the Appendix.

The COMPARE instruction uses `ALU_SUB` with register write disabled (flags-only). The TEST instruction uses `ALU_TEST` with register write disabled (flags-only): the Z flag reflects whether `(sX AND sY/kk)` is zero, and the carry flag is set to the odd parity of the AND result. COMPARECY and TESTCY are the carry-chaining variants: they use `ALU_COMPARECY` and `ALU_TESTCY` respectively, also flags-only. Both propagate the zero flag via `z_i` so that multi-byte comparisons and tests work correctly.

The datapath has several ways to move data without performing arithmetic:

#table(
  columns: (auto, 1fr, 1fr),
  table.header("Mode", "Data Flow", "Used For"),
  `ALU_NOP`, "Outputs zero", "Pipeline stalls (bubble insertion)",
  `ALU_PASS_B`, "Outputs B (register or constant)", "LOAD instructions: copies sY to sX, or loads constant kk into sX",
  `use_data_in`,
  "Bypasses ALU, writes external data directly",
  "INPUT and FETCH instructions: data from IO or memory goes straight to register",
)

`LOAD sX, kk` uses `ALU_PASS_B` with `use_const_in = 1`, so the constant is fed into the B input and passed through. The `use_data_in` path is different: it bypasses the ALU result entirely and selects `data_in` for write-back instead.

=== Flags

The datapath maintains two status flags:

#table(
  columns: (auto, auto, 1fr),
  table.header("Flag", "Width", "Description"),
  "Carry", "1 bit", "Set when an arithmetic operation produces a carry or borrow",
  "Zero", "1 bit", "Set when the result of an operation is zero",
)

Flags are only updated when the `flag_write_in` signal is active, so instructions like LOAD do not affect the flags.

The flag outputs use a bypass path to provide new flag values immediately when a flag-affecting instruction is in the execute stage. Without this, branch instructions (like `JUMP.Z`) would not see the result of the previous instruction in time.

*Pseudocode:*
```vhdl
carry_flag_out = carry_s         when flag_write_delay1 = 1
                 carry_reg       otherwise

zero_flag_out  = 1               when flag_write_delay1 = 1 AND writeback = 0x00
                 0               when flag_write_delay1 = 1 AND writeback != 0x00
                 zero_reg        otherwise
```

When `flag_write_delay1` is active (the pipelined version, aligned with the execute stage), the combinational output from the ALU (`carry_s`) and the writeback comparison are used directly. Otherwise, the registered values (`carry_reg`, `zero_reg`) are output. So a sequence like:

*Assembly:*
```asm
SUB s0, s1      ; sets zero flag if s0 - s1 = 0
JUMP.Z label    ; can branch based on the SUB result
```

works without needing an extra cycle.

=== Writeback

The write-back mux selects what data gets written to the register file. There are two sources:

#table(
  columns: (auto, auto, 1fr),
  table.header("Source", "Selected when", "Used by"),
  "ALU result", `use_data_in = 0`, "Most instructions (ADD, SUB, LOAD, etc.)",
  "External data", `use_data_in = 1`, "INPUT and FETCH instructions",
)

*Pseudocode:*
```vhdl
writeback_s <= data_in when use_data_delay1_s = '1' else alu_result;
```

For INPUT, data comes from the IO unit. For FETCH, data comes from data memory. The ALU result is ignored and external data goes straight to the destination register.

=== Interface

Signals exposed by the datapath:

#table(
  columns: (auto, auto, auto, 1fr),
  table.header("Signal", "Direction", "Width", "Description"),
  `clock_in`, "Input", "1", "System clock",
  `reset_in`, "Input", "1", "Synchronous reset",
  `stall_in`, "Input", "1", "Pipeline stall signal",
  `flush_in`, "Input", "1", "Pipeline flush signal (clears execute stage on branch)",
  `op_in`, "Input", "-", "ALU operation to perform",
  `addrA_in`, "Input", "4", "Register address for operand A / write destination",
  `addrB_in`, "Input", "4", "Register address for operand B",
  `const_in`, "Input", "8", "Immediate constant value",
  `use_const_in`, "Input", "1", "Select constant instead of register B",
  `data_in`, "Input", "8", "External data input (from memory or IO)",
  `use_data_in`, "Input", "1", "Select external data for write-back",
  `do_write_in`, "Input", "1", "Enable register write",
  `flag_write_in`, "Input", "1", "Enable flag update",
  `address_out`, "Output", "8", "ALU B-input (sY or kk) used as address (for OUTPUT/STORE/INPUT/FETCH)",
  `data_out`, "Output", "8", "Value of register A (for OUTPUT/STORE)",
  `carry_flag_out`, "Output", "1", "Current carry flag value",
  `zero_flag_out`, "Output", "1", "Current zero flag value",
  `write_addr_out`, "Output", "4", "Delayed write address (for hazard detection)",
  `write_enable_out`, "Output", "1", "Delayed write enable (for hazard detection)",
)
