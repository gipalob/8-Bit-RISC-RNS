# 8-Bit RISC-V (esque) Microprocessor with Residue Numbering System ISA Extension

This implementation is foundationally based on NayanaBannur/8-bit-RISC-Processor, with a few important modifications outside of RNS support.
1) Modularity:
> `processor_core.v` from the original implementation has been seperated out into distinct modules and had their I/O refactored to improve modularity & clarity. 

2) 64K Data Memory:
> The original implementation only supported an 8-bit addressable data memory; for many applications, 256 data memory elements is incredibly limiting. Load & Store operations were modified to accept 3 register inputs instead of a single register input and an 8-bit constant, increasing the versatility of memory operations (addresses held in registers vs embedded in an instruction), and allowing the concatenation of two register's contents to form an 8-bit address. 

3) QOL ISA Improvements
`LDI` Instruction:
- Load an 8-bit immediate value into a register.
Hazard Detection:
- The original implementation had some 'holes' in hazard detection. For example, if you attempt to execute this series of instructions:
>  `COMPARE x1, x2`
>  `JMPEQ 0x211`
>  `JMP 0x219`
- If x1 == x2, `JMPEQ` will execute and set the program counter to 0x211 when it reaches the end of EX. However, by this point, `JMP 0x219` has finished IF/ID as well, and in the original implementation there was no hazard detection / instruction invalidation for `JMP` instructions. The instruction at 0x211 will enter IF/ID, and then the next cycle the program counter is set to 0x219. To reiterate- this _does not apply_ to other instructions- if `JMPEQ` evaluates true, and the instruction directly afterwards is, say, `ADD`, the `invalidate_instr` signal will keep `reg_wr_en` LOW when the `ADD` enters `MEMWB`. This was fixed by conditionally assigning branch_taken in the EX pipeline register based on its last state.

## ISA Organization:
Instructions are all 16-bits long. 
### R-Type Instructions
| Bit   | Assignment      |
| :---: | :-------------: |
| 15    | opcode[4]       |
| 14    | opcode[3]       |
| 13    | opcode[2]       |
| 12    | opcode[1]       |
| 11    | opcode[0]       |
| 10    | rd[2]           |
|  9    | rd[1]           |
|  8    | rd[0]           |
|  7    | rs2 Domain Flag |
|  6    | rs2[2]          |
|  5    | rs2[2]          |
|  4    | rs2[2]          |
|  3    | rs1 Domain Flag |
|  2    | rs1[2]          |
|  1    | rs1[1]          |
|  0    | rs1[0]          |

- The rs1/rs2 domain flags indicate which register file rs1/rs2 are sourced from; The RNS domain or integer domain register file. Unused for standard R-Type instructions, but important for R-M type (R-Modular) instructions.
- For R-M type instructions, rd will always be a RNS domain register, with the only exceptions being `(Reconstruct instruction? Output instruction?)`


### I-Type Instructions
| Bit   | Assignment      |
| :---: | :-------------: |
| 15    | opcode[4]       |
| 14    | opcode[3]       |
| 13    | opcode[2]       |
| 12    | opcode[1]       |
| 11    | opcode[0]       |
| 10    | rd[2]           |
|  9    | rd[1]           |
|  8    | rd[0]           |
|  7    | imm[7]          |
|  6    | imm[6]          |
|  5    | imm[5]          |
|  4    | imm[4]          |
|  3    | imm[3]          |
|  2    | imm[2]          |
|  1    | imm[1]          |
|  0    | imm[0]          |

- Only one I-Type instruction at the moment: `LDI`.

### J-Type Instructions
| Bit   | Assignment      |
| :---: | :-------------: |
| 15    | opcode[4]       |
| 14    | opcode[3]       |
| 13    | opcode[2]       |
| 12    | opcode[1]       |
| 11    | opcode[0]       |
| 10    | None            |
|  9    | branch_addr[9]  |
|  8    | branch_addr[8]  |
|  7    | branch_addr[7]  |
|  6    | branch_addr[6]  |
|  5    | branch_addr[5]  |
|  4    | branch_addr[4]  |
|  3    | branch_addr[3]  |
|  2    | branch_addr[2]  |
|  1    | branch_addr[1]  |
|  0    | branch_addr[0]  |

- All Jump-Type instructions take a 10-bit immediate value for the instruction address of the target. Jumps are completed unconditionally (`JMP`), or conditionally (`JMPLT`, `JMPGT`, `JMPEQ`, `JMPC`) based on the flags raised by a prior arithmetic operation (Nominally, `COMPARE`)




## RNS Implementation Methodology
