The CPU (`cpu.vhd`) is a PicoBlaze-compatible 8-bit processor with a 2-stage pipeline (fetch/decode and execute/writeback). It connects five main components:

- *Control Unit* -- decodes the 18-bit instruction word from ROM into all datapath, memory, and IO control signals. Contains the program counter and branch logic.
- *Datapath* -- register file (16 × 8-bit) and ALU with pipeline registers that delay control signals by one cycle to align them with the execute stage.
- *Hazard Detector* -- combinational logic that compares the execute-stage write address against the decode-stage read addresses. Stalls the pipeline for one cycle on RAW conflicts.
- *Memory Unit* -- instruction ROM (4096 × 18-bit, asynchronous read) and scratchpad RAM (256 × 8-bit, synchronous write, asynchronous read).
- *IO Unit* -- 256-port input/output interface. Outputs are registered, inputs are combinational.

== Signal Flow

Each cycle, the ROM delivers an instruction at the current PC. The control unit decodes it immediately, producing ALU operation, register addresses, immediate values, and branch conditions. These signals enter the datapath's pipeline registers and take effect one cycle later in the execute stage.

IO and memory control signals (`io_rd`, `io_wr`, `mem_read`, `mem_write`) are delayed by one cycle in `cpu.vhd` so they fire during execute, when the datapath has valid address and data outputs. On a stall, flush, or reset these delayed signals are cleared to prevent unwanted writes.

The data-input mux in `cpu.vhd` selects the source for register writeback: IO data (INPUT), RAM data (FETCH), or zero (default, letting the ALU result through via the datapath).

== Top-Level Interface

#table(
  columns: (auto, auto, auto, 1fr),
  table.header("Port", "Direction", "Width", "Description"),
  `clk`, "in", "1", "System clock",
  `reset`, "in", "1", "Synchronous reset",
  `in_ports`, "in", "256×8", "External input ports",
  `out_ports`, "out", "256×8", "External output ports",
)
