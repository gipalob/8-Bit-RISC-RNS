# Actual instructions for hex-encoded big_mem_test.txt. writes to all mem locations
## Inst                 | Bin (op, rd, rs2, rs1) | Hex 
0)  NOP                 | 00000 000 0000 0000
1)  LDI x1, 0x00        | 10010 001 00000000       9100     *store 0*
2)  LDI x2, 0x00        | 10010 010 00000000       9200     *lower 8-bits of addr*
3)  LDI x3, 0x00        | 10010 011 00000000       9300     *upper 8-bits of addr*
4)  LDI x4, 0x01        | 10010 100 00000001       9401     *iterate by 1 each loop*
5)  LDI x5, 0xFF        | 10010 101 11111111       95FF     *compare ref value*

6)  NOP                                                     *currently required, no stall insertion on branch detection. program counter is naive*
7)  ADD x2, x2, x4      | 00001 010 0 010 0 100    0A24     *add 1 to lower-8b*
8)  RSTORE x2, x3, x2   | 01001 010 0 011 0 010    4A32     *store x2 to {x3, x2}
9)  COMPARE x2, x5      | 01101 000 0 101 0 010    6852     *compare lower 8-bits to FF*
10) JMPLT 0000001100    | 01111 0 0000000110       7806     *if x2 < FF, jump to inst 6*

11) COMPARE x3, x5      | 01101 000 0 011 0 101    6835     *compare upper 8-bits to FF*
12) JMPEQ 0001111111    | 10000 0 0001111111       807F     *if EQ, effectively exit prog*
13) ADD x2, x1, x1      | 00001 010 0 001 0 001    0A11     *re-set x2 to 0*
14) ADD x3, x3, x4      | 00001 011 0 011 0 100    0B34     *add 1 to upper-8b*
15) RSTORE x2, x3, x2   | 01001 010 0 011 0 010    4A32     *store x2 to {x3, x2}
16) JMP 0000000110      | 00111 0 0000000110       3806     *jump to inst 6*
