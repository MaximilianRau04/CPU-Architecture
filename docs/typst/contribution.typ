#import "template.typ": *

#show: project.with(
  title: "RO2 - Group 2",
  authors: ("Berke Özmen", "Dominik Knaup", "Lukas Kurz", "Maximilian Rau", "Mouhammad Mahdi Bazzoun", "Muhammed Sahin"),
)

#set heading(numbering: none)

= Contributions

== Mouhammad Mahdi Bazzoun

=== Features

- *ALU implementation* -- Built the ALU (`src/DataPath/alu.vhd`) with arithmetic, logic, shift/rotate, and TEST. ALU_NOP and ALU_PASS_B were added later by Lukas.

- *Register file* -- Did the register file (`src/DataPath/regfile.vhd`) together with Lukas. 16 registers, two read ports, one write port, resets synchronously.

- *Pipelining* -- Implemented the 2-stage pipeline in the datapath: added the pipeline registers that delay control signals from decode to execute, and `stall_in` handling that clears them to a bubble on hazards.

- *Hazard detection* -- Wrote the RAW hazard detection logic in `cpu.vhd`, then moved it into its own entity (`src/HazardDetection/hazard_detector.vhd`) for a cleaner structure. Pure combinational, stalls when the execute stage writes a register that the decode stage needs to read.

- *CPU top-level* -- Added proper entity ports (`clk`, `reset`, `in_ports`, `out_ports`) to `cpu.vhd`.

- *CPU simulation wrapper* -- Created `sim/cpu_wrapper_tb.vhd` to look at waveforms in Vivado. Wraps Lukas' Fibonacci program with clock and reset so you can inspect all internal CPU signals.

- *Datapath reset logic* -- Added `reset_in` to the datapath and register file so everything gets cleared properly on reset.

- *CI/CD pipeline* -- Set up the GitHub Actions workflow (`.github/workflows/vhdl-test.yml`) so the testbenches run automatically on every push using GHDL.

- *Testbenches* -- Wrote testbenches for: ALU, register file, hazard detector, datapath flush and data_in writeback, CPU integration (proper testbench for Lukas' Fibonacci program), CPU stall hazard (false stall + real stall), CPU pipeline interactions (chained stalls, stall-then-branch, reset recovery), CPU instruction coverage (NOP, TEST, INPUT, OUTPUT_REG, STORE/FETCH round-trip), and ADDCY zero flag chaining (`sim/cpu_addcy_zero_tb.vhd`, tests z_i=1 and z_i=0 through the full pipeline with conditional jumps). Extended the existing datapath and control unit testbenches with flag preservation, stall, and flag_write assertions.

- *ALU z_i input* -- Added a `z_i` input to the ALU for the previous zero flag, wired it to `zero_reg` in the datapath, and switched the datapath to use the ALU's `z_o` instead of computing zero on its own. ADDCY/SUBCY use it for multi-byte zero propagation.

- *COMPARECY and TESTCY* -- Implemented COMPARECY and TESTCY in the ALU and decoder (four opcodes total). COMPARECY is like SUBCY but flag-only, TESTCY chains carry and zero through `c_i`/`z_i`. Updated the ALU, decoder, and datapath testbenches for all of it.

=== Issues

- *Hazard detection stall logic* -- The original stall logic compared the execute-stage write address against raw instruction bits from decode. For jumps and branches, those bits encode the target address, not register operands, so we got spurious stalls whenever the target bits happened to match the write register. Fixed this by adding `reads_reg_a` / `reads_reg_b` signals from the decoder so the hazard detector only stalls when the decode stage actually reads the conflicting register.

- *IO timing off by one cycle* -- After moving from multi-cycle to pipelined execution, OUTPUT and INPUT fired one cycle before the data was ready. Added IO pipeline delay registers (`io_wr_delayed`, `io_rd_delayed`) in `cpu.vhd` to align IO control signals with the execute stage.

- *Flag registers lived inside the ALU* -- Flags were computed and stored inside the ALU, which meant every instruction overwrote them. Moved the flag registers into the datapath, added `flag_write` output to the instruction decoder for all 28 flag-affecting opcodes, and wired `flag_write_in` through the control unit so only flag-affecting instructions (ADD, SUB, AND, OR, XOR, COMPARE, TEST, shifts/rotates) actually update carry and zero. This also fixed ADDCY/SUBCY which were reading a stale carry value.

- *SRA system test carry tracking* -- The SRA test wasn't tracking carry across chained shifts. Moved the carry state outside the loop so it persists between iterations.

- *ALU zero flag not KCPSM6-compliant* -- The ALU had no `z_i` input, so ADDCY/SUBCY couldn't propagate the zero flag for multi-byte arithmetic. Also missing COMPARECY and TESTCY entirely.

#pagebreak()

== Berke Özmen

=== Features

- *Instruction ROM* -- Implemented a synthesizable boot ROM (`InstructionMemory.vhd`) with parameterized address and data widths. Encapsulated instruction encodings via helper functions for LOAD, ADD, SUB, COMPARE, JUMP, and OUTPUT. Default ROM content implements a Fibonacci program used for system validation.

- *Data memory* -- Implemented a 256×8-bit scratchpad RAM (`DataMemory.vhd`) with synchronous writes and asynchronous reads. Added a debug port at address 0xFF for simulation reporting and detection of undefined (X/U) writes.  

- *Memory architecture decisions* -- Applied Harvard memory separation and used distributed RAM attributes for FPGA synthesis compatibility.

- *Boot program* -- Wrote a simple Fibonacci program as default ROM content to validate CPU control flow, register operations, and IO functionality.

- *Directed RAM testbench* -- Created a self-checking testbench covering power-up initialization, write/read behavior, write protection, debug port persistence, and multi-address sweeps.

- *CPU stress testbench* -- Developed a multi-phase system-level testbench including cold start reset, Fibonacci execution, mid-execution reset recovery, and input port noise handling. Includes timeout mechanisms and assertion-based verification.

- *Assertion-driven verification* -- All testbenches use assertions to detect functional errors deterministically, improving reproducibility and eliminating the need for manual waveform inspection.

- *RAM integration* -- Wired RAM into the CPU.

#pagebreak()

== Dominik Knaup

=== Features

- *Presentation* -- Made the initial project presentation together with Maximilian Rau.

- *Instruction decoder* -- Built the instruction decoder (`src/ControlUnit/instruction_decoder.vhd`). Decodes the 18-bit instruction word into all control signals for ALU, register writeback, memory/IO access, immediates, and branch conditions across all PicoBlaze opcodes.

- *Control unit types package* -- Created `src/ControlUnit/controlunit_pkg.vhd` defining the `jump_cond_t` enumerated type (`J_NONE`, `J_UNCOND`, `J_Z`, `J_NZ`, `J_C`, `J_NC`) shared across the instruction decoder, branch logic, and control unit top level.

- *Architecture diagrams* -- Designed the system architecture diagrams for the CPU in draw.io, togehter with Maximilian, Lukas and Mahdi.

- *README* -- Rewrote the README with an ASCII architecture diagram, feature list, project structure, and getting started instructions for Vivado.

- *PR reviews* -- Reviewed and merged pull requests from other team members throughout the project.

- *Control unit testbenches* -- Extended and improved the control unit testbenches (`sim/ControlUnit/instruction_decoder_tb.vhd`, `sim/ControlUnit/control_unit_tb.vhd`) with additional test cases, improved assertions, and better signal documentation during the final code review.

- *Initial CI/CD pipeline* -- Set up an early version of the GitHub Actions workflow for automated VHDL testbench execution using GHDL, so that tests ran automatically on every push. This was later replaced by Mahdi's improved CI/CD pipeline with better structure and additional test coverage.

=== Issues

- *Architecture diagram iterations* -- The initial block diagrams didn't map well to the actual implementation because we lacked the hands-on experience.

- *CI/CD false positives* -- The initial GitHub Actions workflow always reported a successful run, even when individual testbenches failed. The GHDL test runner exit code wasn't propagated correctly to the workflow step, so GitHub Actions marked the job as passed regardless of the actual test outcome.

- *Stale constant values leaking into datapath* -- The immediate constant from the instruction word was always driven onto the datapath bus, even for register-to-register instructions where `use_const_s = '0'`. This caused stale values to leak into the ALU B-input. Fixed in `cpu.vhd` by gating the immediate extraction so the bus is zeroed out for non-immediate instructions.

- *PC overflow at address boundary* -- The program counter didn't wrap properly when it reached the maximum 12-bit address. Added proper wrap-around logic so the PC resets to zero instead of overflowing.

#pagebreak()

== Lukas Kurz

=== Components

/ Datapath: Created the datapath (`src/DataPath/datapath.vhd`), connecting the register file to the ALU and handling writebacks. First version of the datapath testbench. Timing corrections for pipelining.

/ CPU integration: Initial integration of control-unit, datapath and rom in `cpu.vhd`.

/ Assembler: Simple assembler written in C\#. Prints vhdl-formatted machine-code on stdout that can directly be pasted into ROM.

/ Register file sync reads: Changed the register file from async to sync reads for pipelining. Did the register file together with Mahdi.

/ ALU additions: Added `ALU_NOP` and `ALU_PASS_B` to the ALU to support `LOAD` etc.

=== Testing

/ Fibonacci: Creation of a simple program calculating the fibonacci numbers (Default ROM content). Used for testing basic alu and control-flow functionality during early development.

/ Manual: Manual testing in Vivado with `cpu_wrapper_tb.vhd`.

/ System tests: Test framework (`tests/system-test.cs`) for black-box-testing most of the instructions with every possible input combination. Generates VHDL test-benches with custom ROM that are simulated using GHDL in the CI/CD pipeline.

=== Documentation

/ Instructions: Documentation of the instruction-set and its encoding.

/ Datapath: Documentation of the datapath architecture together with Mahdi.

/ Setup: Typst template, syntax highlighting and circuit-diagram rendering.

#pagebreak()

== Maximilian Rau

=== Features & Contributions

- *Control Unit Implementation* -- Designed and implemented the top-level Control Unit (`src/ControlUnit/control_unit.vhd`) to integrate internal entities, including the Branch Logic (`branch_logic.vhd`) and the Program Counter (`program_counter.vhd`).

- *Pipeline Flush Mechanism* -- Introduced `flush_out` to the Control Unit and `flush_in` to the datapath, ensuring the pipeline is correctly cleared whenever a branch is taken.

- *Verification* -- Developed comprehensive testbenches for the Branch Logic, Program Counter, and top-level Control Unit to verify accurate routing and execution. Wrote a dedicated CPU flush testbench (`sim/cpu_flush_tb.vhd`) to validate pipeline stall and flush behavior.

- *Datapath Refactoring* -- Improved architectural separation of concerns by moving the immediate decoding from the datapath to the Instruction Decoder. Refactored datapath multiplexers to use clean concurrent assignments.

- *IO Control Signals* -- Extended the Instruction Decoder and Control Unit to properly generate IO read/write access signals.

- *Instruction Verification* -- Expanded the CPU instruction testbench (`cpu_instruction_tb.vhd`) by implementing specific test cases to validate the behavior of the `COMPARECY` and `TESTCY` instructions.

- *System Architecture & Documentation* -- Designed the system architecture diagrams (via draw.io) with Dominik, Lukas, and Mahdi. Wrote documentation of the Control unit architecture together with Dominik.

- *Team Collaboration* -- Made the initial project presentation together with Dominik Knaup. Consistently reviewed and merged pull requests, ensuring code quality across the team.

=== Resolved Issues & Bug Fixes

- *IO Timing Synchronization* -- Resolved an off-by-one-cycle timing mismatch in the IO operations by reworking `IO_Unit.vhd` and adjusting the CPU-to-datapath wiring.

- *Branch Logic Expansion* -- Identified and fixed a missing edge case in the branch logic by adding support for unconditional jumps.

- *ALU SRA Carry Bug* -- Debugged and fixed an issue where the Shift Right Arithmetic (`SRA`) instruction failed to set the carry flag correctly. Updated the corresponding ALU testbenches accordingly.

- *Opcode & Integration Fixes* -- Corrected the `ALU_NOP` opcode mismatch across the Instruction Decoder and ALU package. Resolved various system-level integration issues spanning the ALU, decoder, shared types, and CPU top-level.

- *Testbench Maintenance* -- Iteratively debugged and fixed various control unit testbenches, correcting invalid opcodes and improving error message clarity.

#pagebreak()

== Muhammed Sahin

=== Features

- *IO Unit* -- Wrote the IO unit (`src/IO_Unit/IO_Unit.vhd`). Handles reading from input ports and writing to output ports, selected by the port address from the decoder.

- *IO types package* -- Created `src/pkg/io_types_pkg.vhd` defining the `port_array` type used for the input/output port arrays.

- *IO Unit testbench* -- Wrote the testbench (`sim/IO_Unit/IO_Unit_TB.vhd`) covering read and write operations across different ports.

- *IO wiring in CPU* -- Added the IO signals to `cpu.vhd` and instantiated the IO unit, connecting it to the control unit and datapath.
