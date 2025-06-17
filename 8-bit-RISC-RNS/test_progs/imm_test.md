# Actual instructions for hex-encoded imm_test.txt:
## Inst             | Binary (opcode, rd, rs2, rs1)
1) NOP              | 00000 000 0000 0000
2) LDI x1, 0xFF     | 10010 001 11111111
3) LDI x2, 0xF0     | 10010 010 11110000
4) SUB x1, x1, x2   | 00010 001 0 010 0 001
5) LDI x3, 0x14     | 10010 011 00010100
6) ADD x4, x1, x3   | 00001 100 0 001 0 011

# Expected final register contents:
x0: x
x1: 0x0F = 15
x2: 0xF0 = 240
x3: 0x14 = 20
x4: 0x23 = 35