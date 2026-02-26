The CPU uses a 2-stage pipeline. Each instruction takes 2 clock cycles to complete, but under normal operation a new instruction starts every cycle.

=== Pipeline Stages

#table(
  columns: (auto, auto, 1fr),
  table.header("Stage", "Cycle", "Operations"),
  "Fetch/Decode", "1", "Instruction is read from ROM. Control unit decodes opcode and operands. Register file reads source registers (A and B).",
  "Execute/Writeback", "2", "ALU performs the operation. Result is written back to the destination register.",
)

The pipeline registers in the datapath delay control signals (ALU operation, write enable, flag write, etc.) by one cycle so they stay aligned with the data flowing through the register file and ALU.

=== Data Hazards

A RAW (Read After Write) hazard occurs when an instruction in the decode stage needs to read a register that the instruction in the execute stage is about to write. Since the write hasn't happened yet, the decode stage would read stale data.

*Example:*
```asm
LOAD s0, 0x42    ; Execute stage: writing 0x42 to s0
ADD  s1, s0      ; Decode stage: wants to read s0, but s0 still has old value
```

=== Hazard Detection

The CPU detects hazards by comparing the write address of the instruction in execute with the read addresses of the instruction in decode:

*Pseudocode:*
```vhdl
stall = write_enable_out
    AND ((write_addr = addrA AND reads_reg_a = 1)
      OR (write_addr = addrB AND reads_reg_b = 1))
```

The `reads_reg_a` and `reads_reg_b` signals come from the decoder and indicate whether the current instruction actually reads each register operand. This avoids false stalls for instructions that don't read a given register (LOAD and FETCH don't read sX, immediate-form instructions don't read sY, jumps don't read either).

=== Stall Behavior

When a hazard is detected, the CPU stalls for one cycle:

#table(
  columns: (auto, 1fr),
  table.header("Action", "Effect"),
  "PC held", "Same instruction stays in decode stage",
  "Bubble inserted", "Execute stage gets neutralized control signals",
)

During a stall or flush, the datapath clears all execute-stage control signals:

#table(
  columns: (auto, 1fr),
  table.header("Signal", "Value during stall/flush"),
  `op_alu_s`, "ALU_NOP",
  `do_write_delay1_s`, "0 (no register write)",
  `flag_write_delay1_s`, "0 (flags unchanged)",
)

After the stall, the execute stage completes its write and the decode stage reads the correct value.

=== Flush Behavior

When a branch is taken, the next instruction already in the decode stage needs to be thrown away. The `flush_in` signal clears the execute-stage pipeline registers just like a stall (inserting a bubble), but unlike a stall the PC is not held. Instead, the control unit updates it to the branch target.
