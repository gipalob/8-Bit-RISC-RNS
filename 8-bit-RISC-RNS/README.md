# 8-Bit RISC-V (esque) Microprocessor with Residue Numbering System ISA Extension

This implementation is foundationally based on NayanaBannur/8-bit-RISC-Processor, with a few important modifications outside of RNS support.
1) Modularity:
> `processor_core.v` from the original implementation has been seperated out into distinct modules and had their I/O refactored to improve modularity & clarity. 

2) 64K Data Memory:
> The original implementation only supported an 8-bit addressable data memory; for many applications, 256 data memory elements is incredibly limiting. Load & Store operations were modified to accept 3 register inputs instead of a single register input and an 8-bit constant, increasing the versatility of memory operations (addresses held in registers vs embedded in an instruction), and allowing the concatenation of two register's contents to form an 8-bit address. 

3) QOL ISA Improvements
> `LDI` Instruction: Load an 8-bit immediate value into a register.

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


## RNS Implementation Methodology
