The memory unit follows a Harvard architecture, with separate memories for instructions and data. The instruction memory is 18 bits wide to fit the full instruction word, while the data memory uses 8-bit words matching the ALU and register file.

=== Instruction Memory (ROM)

The ROM stores the program as a constant array. Reads are asynchronous, so the instruction is available in the same cycle the program counter updates.

Helper functions (`Op_Load_Im`, `Op_Add_Reg`, etc.) encode instructions from human-readable parameters into 18-bit machine words, replacing raw binary strings.

The `distributed` `rom_style` attribute tells the synthesizer to use LUTs instead of block RAM.

#table(
  columns: (auto, auto, 1fr),
  table.header("Parameter", "Value", "Description"),
  "Data Width", "18 bits", "Opcode + register addresses + immediate value",
  "Address Width", "12 bits", "4096-word address space for jump targets",
  "Read Mode", "Asynchronous", "Instruction available without clock delay",
)

=== Data Memory (RAM)

The data memory is an 8-bit scratchpad. Reads are asynchronous (result available in the same cycle), writes are synchronous to the rising clock edge.

Writing to address 0xFF prints the written value to the simulation console, which is useful for debugging without a waveform viewer.

#table(
  columns: (auto, auto, 1fr),
  table.header("Parameter", "Value", "Description"),
  "Data Width", "8 bits", "Matches ALU word size",
  "Address Width", "8 bits", "256 locations",
  "Write Mode", "Synchronous", "Registered on rising clock edge",
  "Read Mode", "Asynchronous", "Single-cycle read",
)

=== Verification

The `MemoryUnit_TB` tests basic read/write, write protection (verifying that data is not written when `Write_En = 0`), the debug port at 0xFF, and a sweep over a range of addresses.

The `cpu_stress_tb` runs the Fibonacci program on the full CPU and checks:
- Correct output sequence (1, 1, 2, 3, 5)
- Recovery after a mid-execution reset
- No undefined outputs after input port noise
