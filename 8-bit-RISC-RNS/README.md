# 8-Bit RISC-V (esque) Microprocessor with Residue Numbering System ISA Extension

This implementation is foundationally based on NayanaBannur/8-bit-RISC-Processor, with a few important modifications outside of RNS support.
1) Modularity:
    - `processor_core.v` from the original implementation has been seperated out into distinct modules and had their I/O refactored to improve modularity & clarity. 

2) 64K Data Memory:
    -  The original implementation only supported an 8-bit addressable data memory; for many applications, 256 data memory elements is incredibly limiting. Load & Store operations were modified to accept 3 register inputs instead of a single register input and an 8-bit constant, increasing the versatility of memory operations (addresses held in registers vs embedded in an instruction), and allowing the concatenation of two register's contents to form an 8-bit address. 

3) QOL ISA Improvements
    - `LDI` Instruction:
        - Load an 8-bit immediate value into a register.
    - Hazard Detection:
        - The original implementation had a 'hole' in hazard detection. For example, if you attempt to execute this series of instructions:
        ```
        COMPARE x1, x2
        JMPEQ 0x211
        JMP 0x219
        ```
        - If x1 == x2, `JMPEQ` will execute and set the program counter to 0x211. However, by this point, `JMP 0x219` has finished IF/ID as well. The problem is that the original implementation had no instruction invalidation for `JMP` instructions. The instruction at 0x211 will enter IF/ID, and then the next cycle the program counter is set to 0x219. This was fixed by conditionally assigning branch_taken in the EX pipeline register based on its last state.
        -   This _does not apply_ to other instructions- if `JMPEQ` evaluates `true`, and the instruction at the line below is, say, `ADD`, the `invalidate_instr` signal will keep `reg_wr_en` LOW when the `ADD` enters `MEMWB`.

## ISA Organization:
<ins>**Instructions are all 16-bits long.**</ins>
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

- The rs1/rs2 domain flags indicate which register file rs1/rs2 are sourced from; The RNS domain or integer domain register file. Note that 'rs3', which is taken from the bit-indices that are normally designated for rd, and exclusively used for `RLOAD` and `RSTORE`, is always a 3-bit address signal.
- For R-M type instructions, rd will always be a RNS domain register.


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

- All Jump-Type instructions take a 10-bit immediate value for the instruction address of the target. Jumps are completed unconditionally (`JMP`), or conditionally (`JMPLT`, `JMPGT`, `JMPEQ`, `JMPC`) based on the flags raised by a prior integer-domain arithmetic operation (Nominally, `COMPARE`)




## RNS Implementation Methodology
As mentioned in the R-Type instruction description, there are two bits of the instruction used to designate which register file operands are pulled from- the RNS domain register file, or the integer domain register file. This means that we don't need an assortment of instructions (i.e., RNS-specific LDI, MV-RNS to move register contents from int-domain reg to RNS-domain reg, LD-RNS {to load int-domain data in data memory into RNS-domain registers}) and can 'load' data into the RNS-domain registers simply by performing an operation on integer-domain registers.That means, the below instruction sequence is valid, in spite of the operands not initially being in the RNS-domain:
```
LDI x0, 0x14
LDI x1, 0x23
MULMD m0, x0, x1
```
Where the 'm' register prefix indicates an RNS-domain register.
-  Note that for R-type instructions, although rs1 & rs2 are (effectively) 4-bit register addresses, rd is **_not_**. The domain of the destination register is determined by the opcode of the instruction.
-  Another worthwhile note is that as RNS-Domain instructions are able to use integer domain source registers (and because rd can only be 3 bits due to instruction length limitations) LDI _cannot_ load into Mod-Domain registers. 

### Important Notes
Care was taken to try to make the logic design of the processor as dynamic as possible. When looking at the code, you'll notice a few parameterized values. The moduli are parameterized, the number of domains is parameterized, and the program counter width is parameterized. *However:*

- Program counter width (`parameter PROG_CTR_WID`) is, in reality, a value that's inherently limited to 10-bits due to the 16 bit instruction length. Theoretically, this could be expanded by one bit as the opcode is 5-bits. However, due to the desire to keep 16-bit instructions (two byte length is convenient, no real need to expand for any other reason) expanding the program counter width isn't particularly feasible. 


- The number of domains (`parameter NUM_DOMAINS`) is also moot, to an extent. Many registers / wires are defined around this parameter, and for the most part, it could be raised with minimal side effects- most of the datapath is designed with this value being dynamic in mind. _However:_
    - Recall that the wires for op1/op2 (and other register-sourced / register-bound wires) are all >8-bit length. Currently, for 8-bit operands, the register file pads the MSBs of its output with 0's. The number of padded 0's is hard-coded, due to the additional logical complexity required to make zero-padding dynamic. The situation is the same anywhere else that zero-padding occurs. 


- The `RLLM` instruction (used, for example, to roll two bytes read from Data Memory into a mod-domain register) can only take **two** register addresses due to the instruction length limitation. For that reason, and the fact that the data memory is 16-bit addressable (no possibility to, say, define a range of addresses in data memory to roll into a single mod-domain register), it wouldn't be efficable to roll more than two bytes together.
    - The story for `UNRL{U/L}` is similar. Already, un-rolling a mod-domain register is seperated into two instructions. Using that methodology, one opcode per modular domain would need to be used for `UNRL` (i.e., `UNRL_d1 rd, mS`, `UNRL_d2 rd, mS`, ... `UNRL_dN, mS`) which isn't efficable. Any other methodology for unrolling wouldn't really be efficable. 




### Modulus Operations
- The output of every RNS-ALU sub-module (Add, subtract, multiply) is 16 bits, as a modulo will always be performed to reduce to 8 bits. This also helps insure that regardless of operation, no data loss can occur due to overflow.

- Additionally, the _only_ place where the actual `% {modulo}` operation is performed is within dedicated `RNS_fit_N` modules. These modules are instantiated depending on the `parameter [8:0] modulo` input to the GENBLK instantation of a given `PL_ALU_RNS` module in `PL_EX`. This makes it quite simple to have an optimized modulo operation for an arbitrary modulus: define a new module containing the optimized algorithm, (for instance) `module RNS_fit_Y`, and add a condition to the `PL_ALU_RNS` module for `if (modulus == 9'dY): Instantiate RNS_fit_Y`. 




## Overview of RNS Instructions
#### <ins>__Arithmetic__</ins>
1) **ADDM rd, rs1, rs2**
    - Add two values, storing the result across the two modular domains. Sources can either be integer-domain or modular-domain.
2) **SUBM rd, rs1, rs2**
    - Subtract two values, storing the result across the two modular domains. Sources can either be integer-domain or modular-domain.
3) **MULM rd, rs1, rs2**
    - Multiply two values, storing the result across the two modular domains. Sources can either be integer-domain or modular-domain. 

For integer domain sources, opN[7:0] is provided to all `PL_ALU_RNS` modules.

#### <ins>__Supplementary__</ins>
1) UNRLL rd, rs1
- Place the lower 8-bits of an RNS register (aka, the value mod Domain1) into an integer domain register. 
2) UNRLU rd, rs1
- Place the upper 8-bits of an RNS register (aka, the value mod Domain2) into an integer domain register.
3) RLLM rd, rs1, rs2
- Roll two integer-domain registers into an RNS register. 

> For UNRLL and UNRLU, if `rs` is not a modular-domain register, no regfile write will occur. The  `write_to_regfile` signal is tied to the domain flag (see instruction bit-index breakdown) for `rs`.

> Additionally, for clarity: None of these instructions perform reconstruction from the RNS.


#### Example RNS Flows
1) Let's say the data memory contains 4 bytes of data, corresponding to two RNS operands. This is what it looks like to load those 4 bytes of data into RNS registers:
```
# Load from datamem 
LDI x0, 0x00
LDI x1, 0x01

RLOAD x4, x0, x0    # Load [15:0] addr = {8'd0, 8'd0} to x4
ADD x2, x0, x1      # x2++
RLOAD x5, x0, x2    # Load [15:0] addr = {8'd0, 8'd1} to x5
ADD x2, x2, x1      # x2++
RLOAD x6, x0, x2    # Load [15:0] addr = {8'd0, 8'd2} to x6
ADD x2, x2, x1      # x2++
RLOAD x7, x0, x2    # Load [15:0] addr = {8'd0, 8'd3} to x7

# Roll into RNS reg
RLLM m0, x4, x5
RLLM m1, x6, x7
```

2) Similarly, let's see what it looks like to store an RNS register to datamem:
```
LDI x0, 0x00
LDI x1, 0x01

UNRLL x4, m0
RSTORE x4, x0, x0   # Store x4 = m0[7:0] to addr = {8'd0, 8'd0}

UNRLU x4, m0
RSTORE x4, x0, x1   # Store x4 = m0[15:8] to addr = {8'd0, 8'd1}
```
