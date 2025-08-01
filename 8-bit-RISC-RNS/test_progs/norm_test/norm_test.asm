NOP
LDI x1, 0x1A #We're printing the alphabet, 26 characters
LDI x2, 0x01
LDI x3, 0x40
LDI x6, 0x0A
LDI x7, 0x0D
LOOP_START:
NOP
LDI x0, 0x00
NOP
LOOP:
NOP
ADD x0, x0, x2
NOP
COMPARE x0, x1 #check if we reached the end of the range
JMPGT LOOP_START
NOP
NOP
NOP
ADD x4, x0, x3 #convert to ASCII (A=65)
JMP OUTCHAR
NOP
NOP
NOP
OUTCHAR: #expects char to be in x4, jumps back to loop at end
NOP
INPUT x5, 0x03
NOP
NOP
COMPARE x5, x2 #check TX buffer full
JMPEQ OUTCHAR # go back to loop if TX buff fullNOP
NOP
NOP
NOP
OUTPUT x4, 0x01 
JMP LOOP