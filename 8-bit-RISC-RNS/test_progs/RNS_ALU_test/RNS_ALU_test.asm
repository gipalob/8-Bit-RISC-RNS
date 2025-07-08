# RNS Arithmetic test for the mod 129/256 RNS 8-bit RISC processor
# test loading and performing an arithmetic operation that's fits in domain
LDI x0, 0x08
LDI x1, 0x02
MULMD m0, x0, x1 #end result m0[15:8] = 00010000, m0[7:0] = 00010000
NOP

# test addition
ADDMD m1, x0, x1 #end result m1[15:8] = 00001010, m1[7:0] = 00001010
NOP

# test subtraction
SUBMD m2, x0, x1 #end result m2[15:8] = 00000110, m2[7:0] = 00000110
NOP

#now, test overflow- first in D129
LDI x2, 0x0A
MULMD m3, m0, x2
#result should be (8*2) * 10 = 160 = (160 % 129) = 31
#so: m3[15:8] = 10100000, m3[7:0] = 00111111

#now, test overflow in D256
MULMD m4, m3, m2
#for %256: 160 * 6 = 960 = (960 % 256) = 192
#for %129: 31 * 6  = 186 = (186 % 129) = 57
#so: m4[15:8] = 11000000, m4[7:0] = 00111001

#last test, for RLLM
RLLM m5, x0, x1