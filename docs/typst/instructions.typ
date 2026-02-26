/* # References #
 *
 * RISC-V: https://www.cs.sfu.ca/~ashriram/Courses/CS295/assets/notebooks/RISCV/RISCV_CARD.pdf
 * KCPSM6: https://www1.hs-bremerhaven.de/kmueller/VHDL/PB_Instr_Ref.pdf */

In this section, we describe the available instructions of a simple RISC processor inspired by PicoBlaze.

== Instruction layout

#table(
  columns: (auto, auto, 1fr),
  table.header("Field", "Size", "Description"),
  "opcode", "6 bits", "operation to be performed",
  "sX", "4 bits", "destination and first source register",
  "sY", "4 bits", "second source register",
  "kk", "8 bits", "immediate 8-bit constant value",
  "aaa", "12 bits", "jump target address",
)

#table(
  columns: (auto, ..range(18).map(x => 1fr)),
  stroke: black,
  table.header(
    table.cell(stroke: none)[],
    ..range(18).map(x => table.cell(stroke: none, text(size: 7pt, str(x)))),
  ),
  table.cell(stroke: none, align: right)[Indirect Instruction:],
  table.cell(colspan: 6)[`opcode`],
  table.cell(colspan: 4)[`sX`],
  table.cell(colspan: 4)[`sY`],
  table.cell(colspan: 4)[],
  table.cell(stroke: none, align: right)[Immediate Instruction:],
  table.cell(colspan: 6)[`opcode`],
  table.cell(colspan: 4)[`sX`],
  table.cell(colspan: 8)[`kk`],
  table.cell(stroke: none, align: right)[Jump Instruction:],
  table.cell(colspan: 6)[`opcode`],
  table.cell(colspan: 12)[`aaa`],
)

== Available instructions

#table(
  columns: (auto, auto, 1fr),
  fill: (x, y) => if (calc.rem(y, 2) == 0 and y != 0) { rgb("eee") },
  table.header("Instruction", "Opcode", "Description"),
  `nop`, `000000`, `//`,
  `add`, `000010`, `sX += sY`,
  `add.im`, `000011`, `sX += kk`,
  `add.carry`, `000100`, `sX += sY + C`,
  `add.carry.im`, `000101`, `sX += kk + C`,
  `sub`, `000110`, `sX -= sY`,
  `sub.im`, `000111`, `sX -= kk`,
  `sub.carry`, `001000`, `sX -= sY - C`,
  `sub.carry.im`, `001001`, `sX -= kk - C`,
  `and`, `001010`, `sX &= sY`,
  `and.im`, `001011`, `sX &= kk`,
  `or`, `001100`, `sX |= sY`,
  `or.im`, `001101`, `sX |= kk`,
  `xor`, `001110`, `sX ^= sY`,
  `xor.im`, `001111`, `sX ^= kk`,
  `compare`, `010000`, `sX - sY`,
  `compare.im`, `010001`, `sX - kk`,
  `compare.carry`, `011110`, `sX - sY - C`,
  `compare.carry.im`, `011111`, `sX - kk - C`,
  `test`, `010010`, `sX & sY`,
  `test.im`, `010011`, `sX & kk`,
  `test.carry`, `101100`, `sX & sY (chain C, Z)`,
  `test.carry.im`, `101101`, `sX & kk (chain C, Z)`,
  `load`, `010100`, `sX = sY`,
  `load.im`, `010101`, `sX = kk`,
  `input`, `010110`, `sX = P[sY]`,
  `input.im`, `010111`, `sX = P[kk]`,
  `output`, `011000`, `P[sY] = sX`,
  `output.im`, `011001`, `P[kk] = sX`,
  `fetch`, `011010`, `sX = M[sY]`,
  `fetch.im`, `011011`, `sX = M[kk]`,
  `store`, `011100`, `M[sY] = sX`,
  `store.im`, `011101`, `M[kk] = sX`,
  table.hline(stroke: black + 0.5pt),
  table.cell(colspan: 3, "10...."),
  table.hline(stroke: black + 0.5pt),
  `rl`, `100000`, "",
  `rr`, `100010`, "",
  `sl0`, `100011`, `sX = (sX << 1) `,
  `sl1`, `100100`, `sX = (sX << 1) | 1`,
  `sla`, `100101`, "",
  `slx`, `100110`, "",
  `sr0`, `100111`, `sX = (sX >> 1) `,
  `sr1`, `101000`, `sX = (sX >> 1) | (1 << 7)`,
  `sra`, `101001`, "",
  `srx`, `101010`, "",
  table.hline(stroke: black + 0.5pt),
  table.cell(colspan: 3, "11...."),
  table.hline(stroke: black + 0.5pt),
  `jump`, `110000`, `PC = aaa`,
  `jump.z`, `110001`, `if (Z) PC = aaa`,
  `jump.nz`, `110010`, `if (!Z) PC = aaa`,
  `jump.c`, `110011`, `if (C) PC = aaa`,
  `jump.nc`, `110100`, `if (!C) PC = aaa`,
)
