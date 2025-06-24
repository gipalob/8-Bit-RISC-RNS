# Actual instructions for hex-encoded haz_detect_test.txt.
## Inst                 | Bin (op, rd, rs2, rs1) | Hex 
LDI x0, 0x0F            | 10010 000 00001111     | 900F
LDI x1, 0xF0            | 10010 001 11110000     | 91F0
LDI x2, 0x11            | 10010 010 00010001     | 9211
LDI x3, 0xFF            | 10010 011 11111111     | 93FF
LDI x4, 0x00            | 10010 100 00000000     | 9400
ADD x5, x2, x4          | 00001 101 0 010 0 100  | 0D24
COMPARE x5, x2          | 01101 000 0 101 0 010  | 6852
JMPEQ 0x0FF             | 10000 0 0011111111     | 80FF
JMP 0x001               | 00111 0 0000000001     | 3801

### If correct execution is followed, the final value of x5 SHOULD NOT be 0xFF.