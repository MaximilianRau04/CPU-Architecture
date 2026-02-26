#import "@preview/cetz:0.3.1"
#import "@preview/circuiteria:0.2.0"

The *Control Unit* decodes the 18-bit instruction word and generates all control signals that steer the datapath, memory, IO, and program flow. It is split into five files with clearly separated responsibilities: `controlunit_pkg.vhd` (shared types), `instruction_decoder.vhd` (opcode decoding), `branch_logic.vhd` (jump evaluation), `program_counter.vhd` (PC register), and `control_unit.vhd` (integration wrapper).

=== Instruction Decoder

The Instruction Decoder (`instruction_decoder.vhd`, `controlunit_pkg.vhd`) is a purely combinational block. It takes the 18-bit instruction word and produces all control signals in a single combinational pass (no clock needed).

==== Instruction Format

Every instruction is 18 bits wide and follows a fixed layout:

#table(
  columns: (auto, auto, auto),
  [*Bits*], [*Field*], [*Description*],
  [`17..12`], [`opcode`], [6-bit operation code],
  [`11..8`], [`sX`], [Destination / source register A (s0--sF)],
  [`7..4`], [`sY`], [Source register B (register-addressed instructions)],
  [`7..0`], [`kk` / `pp`], [8-bit immediate or port address (immediate instructions)],
  [`11..0`], [`aaa`], [12-bit jump target (jump instructions)],
)

The opcode is decoded with a `case` statement. Each branch sets only the signals that differ from the safe defaults (all writes disabled, `ALU_NOP`, no jump).

==== Generated Control Signals

#table(
  columns: (auto, auto),
  [*Signal*], [*Purpose*],
  [`alu_op`], [ALU operation (`ALU_ADD`, `ALU_SUB`, `ALU_AND`, ..., `ALU_TEST`, `ALU_COMPARECY`, `ALU_TESTCY`, `ALU_PASS_B`)],
  [`alu_src`], [ALU B-input source: `0` = register sY, `1` = immediate `kk`],
  [`imm8`], [8-bit immediate value (valid when `alu_src = '1'`)],
  [`reg_dst`], [Destination register index (sX)],
  [`reg_src_b`], [Source register index B (sY)],
  [`reg_write`], [Enables register writeback],
  [`flag_write`], [Enables carry/zero flag update (only for flag-affecting instructions)],
  [`mem_read`], [Scratch-pad read (FETCH)],
  [`mem_write`], [Scratch-pad write (STORE)],
  [`io_rd`], [IO read (INPUT)],
  [`io_wr`], [IO write (OUTPUT)],
  [`jump_cond`], [Branch condition (`J_NONE`, `J_Z`, `J_NZ`, `J_C`, `J_NC`, `J_UNCOND`)],
  [`reads_reg_a`], [Instruction reads register A -- used by Hazard Detector],
  [`reads_reg_b`], [Instruction reads register B -- used by Hazard Detector],
)

==== Instruction Groups

*Arithmetic / Logic* (`ADD`, `ADDCY`, `SUB`, `SUBCY`, `AND`, `OR`, `XOR`): Each exists in a register variant (`sX, sY`) and an immediate variant (`sX, kk`). All set `reg_write = '1'` and `flag_write = '1'`. Immediate variants set `alu_src = '1'` and `reads_reg_b = '0'`.

*Flag-only operations:*
- `COMPARE` reuses `ALU_SUB` but with `reg_write = '0'` -- only updates flags.
- `TEST` uses `ALU_TEST` with `reg_write = '0'` -- computes `sX AND sY/kk` for the Z flag, and sets C to the odd parity of the AND result.
- `COMPARECY` uses `ALU_COMPARECY` with `reg_write = '0'` -- like `SUBCY` but flags-only. Chains the zero flag via `z_i`: `Z = (result = 0) AND z_i`, enabling multi-byte comparisons.
- `TESTCY` uses `ALU_TESTCY` with `reg_write = '0'` -- like `TEST` but chains both carry and zero: `C = parity(result) OR c_i`, `Z = (result = 0) AND z_i`.

*Data transfer* (`LOAD`): Uses `ALU_PASS_B` to pass the source (register or immediate) through the ALU to the destination register. Sets `reads_reg_a = '0'` because sX is only written, not read -- this avoids unnecessary pipeline stalls.

*IO instructions* (`INPUT`, `OUTPUT`): The datapath's `address_out` is wired directly to the ALU B-input (`B_alu`), so the port address (register sY or immediate `kk`) reaches `address_out` without going through the ALU computation.

*Scratch-pad memory* (`FETCH`, `STORE`): Same addressing mechanism as IO -- `address_out` comes directly from `B_alu`, so the memory address (register value or immediate) bypasses the ALU result path.

*Shifts and Rotates* (`RL`, `RR`, `SL0`, `SL1`, `SLA`, `SLX`, `SR0`, `SR1`, `SRA`, `SRX`): Single-operand instructions that only use register A. Each sets `reads_reg_b = '0'`, `reg_write = '1'`, and `flag_write = '1'`. The carry flag is set to the bit shifted out (bit 7 for left shifts, bit 0 for right shifts). `SRX` performs arithmetic right shift (sign extension: bit 7 is preserved). `SRA` shifts right and inserts the carry flag.

*Jumps* (`JUMP`, `JUMP Z`, `JUMP NZ`, `JUMP C`, `JUMP NC`): Set `jump_cond` to the corresponding condition. No register reads (`reads_reg_a = '0'`, `reads_reg_b = '0'`), no writes.

=== Branch Logic, Program Counter & Integration

==== Branch Logic (`branch_logic.vhd`)

The Branch Logic is a purely combinational block that decides whether a jump should be taken. It receives `jump_cond` and `jump_enable` from the decoder/control unit, together with the current flags (`carry_in`, `zero_in`), and produces `branch_taken`. The `jump_enable` signal is `'1'` for any jump instruction (`J_UNCOND`, `J_Z`, `J_NZ`, `J_C`, `J_NC`) and `'0'` for `J_NONE`. When `jump_enable = '0'`, `branch_taken` is always `'0'` regardless of flag values:

#table(
  columns: (auto, auto),
  [*Condition*], [*Taken when*],
  [`J_UNCOND`], [Always],
  [`J_Z`], [`zero_in = '1'`],
  [`J_NZ`], [`zero_in = '0'`],
  [`J_C`], [`carry_in = '1'`],
  [`J_NC`], [`carry_in = '0'`],
  [`J_NONE`], [Never (not a jump instruction)],
)

The flags `carry_in` and `zero_in` come from the datapath with _forwarding_: if the instruction currently in the execute stage updates flags (`flag_write = '1'`), the fresh ALU output is forwarded immediately. Otherwise the registered flag values from a previous instruction are used. This ensures that a conditional jump directly after a flag-affecting instruction (e.g. `COMPARE` followed by `JUMP Z`) evaluates the correct flags without needing an extra wait cycle.

==== Program Counter (`program_counter.vhd`)

The Program Counter is a 12-bit synchronous counter with three behaviors:

- *Reset* (`reset = '1'`): `pc_reg` is cleared to `0x000`.
- *Branch/Jump* (`enable = '1'` and `branch_jump = '1'`): `pc_reg` loads the absolute target address `jump_address` (taken from `instruction(11..0)`).
- *Sequential* (`enable = '1'` and `branch_jump = '0'`): `pc_reg` increments by 1.
- *Stall* (`enable = '0'`): `pc_reg` holds its value -- the same instruction is re-fetched.

Pipeline stages, hazard detection, stall and flush behavior are described in the Pipeline section.

==== Verification (Simulation)

Verification for the Control Unit is split into focused testbenches under `sim/ControlUnit/`:

- `instruction_decoder_tb.vhd`: combinational decoding of opcodes into control signals.
- `branch_logic_tb.vhd`: jump-condition evaluation (`J_Z`, `J_NZ`, `J_C`, `J_NC`, `J_UNCOND`) independent of the PC.
- `program_counter_tb.vhd`: synchronous reset, enable/hold behavior, increment, and absolute jumps.
- `control_unit_tb.vhd`: integration checks (stall gating, PC freeze/advance, and `flush_out` behavior on taken jumps).

=== Figures
The following figures describes the architecture of the Control Unit

#figure(
  circuiteria.circuit({
    import circuiteria: *

    // ── Instruction Decoder (left, large, combinational) ──
    element.block(
      x: 0,
      y: 0,
      w: 7,
      h: 12,
      id: "decoder",
      name: "Instruction Decoder",
      fill: util.colors.yellow,
      ports: (
        west: (
          
        ),
        east: (
          (id: "blank_top", name: ""), // <-- Neuer Abstandshalter oben
          (id: "instr_in", name: "instruction [17:0]"),
          (id: "alu", name: "alu_op, alu_src"),
          (id: "imm", name: "imm8 [7:0]"),
          (id: "reg", name: "reg_dst, reg_src_b"),
          (id: "blank_mid", name: ""), // <-- Nur noch ein Abstandshalter in der Mitte
          (id: "wr", name: "reg_write, flag_write"),
          (id: "mem", name: "mem_read, mem_write"),
          (id: "io", name: "io_rd, io_wr"),
          (id: "haz", name: "reads_reg_a/b"),
          (id: "jcond", name: "jump_cond"),
        ),
      ),
    )

    // ── Branch Logic (right, upper, combinational) ──
    element.block(
      x: 11,
      y: 8,
      w: 7,
      h: 4,
      id: "branch",
      name: "Branch Logic",
      fill: util.colors.yellow,
      ports: (
        west: (
          (id: "jump_enable", name: "jump_enable"),
          (id: "jcond_in", name: "jump_cond"),
        ),
        north: (
          (id: "carry_in", name: "carry_in"),
          (id: "zero_in", name: "zero_in"),
        ),
        south: (
          (id: "taken", name: "branch_taken"),
        ),
      ),
    )

    // ── Program Counter (right, lower, clocked) ──
    element.block(
      x: 11,
      y: 1,
      w: 7,
      h: 4,
      id: "pc",
      name: "Program Counter",
      fill: util.colors.orange,
      ports: (
        north: (
          (id: "branch_jump", name: "branch_jump"),
        ),
        west: (
          (id: "blank", name: ""),
          (id: "blank", name: ""),
          (id: "blank", name: ""),
          (id: "blank", name: ""),
          (id: "blank", name: ""),
          (id: "blank", name: ""),
          (id: "jump_addr", name: "jump_addr [11:0]"),
          (id: "blank", name: ""),
          (id: "clk", clock: true),
        ),
        south: (
          (id: "pc_out", name: "pc_out [11:0]"),
        ),
      ),
    )

    // ── Internal wiring ──

    // Decoder jump_cond → Branch Logic (horizontal, through the gap)
    wire.wire(
      "jcond_wire",
      ("decoder-port-jcond", "branch-port-jcond_in"),
      style: "zigzag",
      zigzag-ratio: 25%,
    )

    // Branch Logic branch_taken → PC branch_jump (vertical, through the gap)
    wire.wire(
      "taken_wire",
      ("branch-port-taken", "pc-port-branch_jump"),
      style: "zigzag",
    )

    // jump_enable (derived from jump_cond) → Branch Logic
    wire.wire(
      "jump_enable_wire",
      ("decoder-port-jcond", "branch-port-jump_enable"),
      style: "zigzag",
      zigzag-ratio: 75%,
    )

    // instruction[11:0] → PC jump_address
    wire.wire(
      "jump_addr_wire",
      ("decoder-port-instr_in", "pc-port-jump_addr"),
      style: "zigzag",
    )

    wire.wire(
      "carry_in_stub",
      ("branch-port-carry_in", (rel: (0, 1), to: "branch-port-carry_in")),
    )

    wire.wire(
      "zero_in_stub",
      ("branch-port-zero_in", (rel: (0, 1), to: "branch-port-zero_in")),
    )

    wire.wire(
      "pc_out_stub",
      ("pc-port-pc_out", (rel: (0, -1), to: "pc-port-pc_out")),
    )

  }),
  caption: [Block diagram: Control Unit -- Instruction Decoder, Branch Logic, and Program Counter.],
)


*Figure description:* This block diagram shows the internal partitioning of the Control Unit. The `instruction` bus feeds the Instruction Decoder, which produces the datapath control (`alu_op`, `alu_src`, register indices, write enables) and the jump condition `jump_cond`. `jump_cond` together with the ALU flags `Z`/`C` is evaluated by the Branch Logic. The resulting jump decision controls whether the Program Counter increments normally or loads the target address.
