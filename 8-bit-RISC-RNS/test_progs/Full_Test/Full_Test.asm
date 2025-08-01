#Full test of HW functions- RNS arithmetic, I/O, Expanded data memory.
LDI x0, 0x00
LDI x1, 0x01
ADDM m2, x0, x1 #set m2 to 1
LDI x5, 0xFF
LDI x6, 0x00 #mem addr [15:8]
LDI x7, 0x00 #mem addr [7:0]

#add loop adds numbers to themselves a bunch and then stores to mem
ADD_LOOP: 
NOP
ADDM m0, m2, m2
ADDM m2, m2, x1
UNRLU x3, m0
RSTORE x3, x6, x7
ADD x7, x7, x1
COMPARE x7, x5 #check if we reached the end of the range
JMPEQ add_IT_MEM_UPPER
NOP
NOP
NOP
UNRLL x3, m0
RSTORE x3, x6, x7
ADD x7, x7, x1
JMP ADD_LOOP
NOP
NOP
NOP
add_IT_MEM_UPPER: #always jumped to in the middle of the loop; so, we still need to store the UNRLL result
NOP
ADD x6, x6, x1
LDI x7, 0x00
UNRLL x3, m0
RSTORE x3, x6, x7
ADD x7, x7, x1
LDI x0, 0x02
COMPARE x6, x0 #we only want to add up to 512 + 512
JMPLT ADD_LOOP
NOP
NOP
NOP

LDI x0, 0x00
ADDM m2, x0, x1 #set m2 to 1

MUL_LOOP:
NOP
MULM m0, m2, m2 #m2*m2
ADDM m2, m2, x1 #m2++
UNRLU x3, m0
RSTORE x3, x6, x7
ADD x7, x7, x1
COMPARE x7, x5 #check if we reached the end of the range
JMPEQ mul_IT_MEM_UPPER
NOP
NOP
NOP
UNRLL x3, m0
RSTORE x3, x6, x7
ADD x7, x7, x1
JMP MUL_LOOP
NOP
NOP
NOP
mul_IT_MEM_UPPER: #always jumped to in the middle of the loop; so, we still need to store the UNRLL result
NOP
ADD x6, x6, x1
LDI x7, 0x00
UNRLL x3, m0
RSTORE x3, x6, x7
ADD x7, x7, x1
LDI x0, 0x05
COMPARE x6, x0 #we only want to mul up to 512 + 512
JMPLT MUL_LOOP
NOP
NOP
NOP

#now we've done the mul and add storing to mem. output via UART now.
#we should've stopped storing RNS add ops at addr before 00000010 00000001
#and mul ops should end at 00000101 00000001
LDI x6, 0x00 #reset mem addr
LDI x7, 0x00 #reset mem addr
UART_OUT:
INPUT x4, 0x03 #check if TX buffer full
NOP
COMPARE x4, x1 #check if TX buffer full
JMPEQ UART_OUT
NOP
NOP
NOP
COMPARE x7, x5
JMPEQ UART_IT_MEM_UPPER
NOP
RLOAD x3, x6, x7 #load from mem
NOP
OUTPUT x3, 0x01 #output to UART
ADD x7, x7, x1 #increment mem addr
JMP UART_OUT
NOP
NOP
NOP
UART_IT_MEM_UPPER:
NOP
ADD x6, x6, x1
LDI x7, 0x00
LDI x0, 0x02
COMPARE x6, x0 #we only want to mul up to 512 + 512
JMPEQ ADD_OUT_END
NOP
LDI x0, 0x05
JMPEQ MUL_OUT_END
NOP
NOP
NOP
JMP UART_OUT
NOP
NOP
NOP
ADD_OUT_END:
NOP
LDI x0, 0x45
AOEC1:
INPUT x4, 0x03 #check if TX buffer full
NOP
COMPARE x4, x1 #check if TX buffer full
JMPEQ AOEC1
NOP
NOP
NOP
OUTPUT x0, 0x01 #output to UART
LDI x0, 0x4E
AOEC2:
INPUT x4, 0x03 #check if TX buffer full
NOP
COMPARE x4, x1 #check if TX buffer full
JMPEQ AOEC2
NOP
NOP
NOP
OUTPUT x0, 0x01 #output to UART
LDI x0, 0x44
AOEC3:
INPUT x4, 0x03 #check if TX buffer full
NOP
COMPARE x4, x1 #check if TX buffer full
JMPEQ AOEC3
NOP
NOP
NOP
OUTPUT x0, 0x01 #output to UART
LDI x0, 0x41
AOEC4:
INPUT x4, 0x03 #check if TX buffer full
NOP
COMPARE x4, x1 #check if TX buffer full
JMPEQ AOEC4
NOP
NOP
NOP
OUTPUT x0, 0x01 #output to UART
LDI x0, 0x44
AOEC5:
INPUT x4, 0x03 #check if TX buffer full
NOP
COMPARE x4, x1 #check if TX buffer full
JMPEQ AOEC5
NOP
NOP
NOP
OUTPUT x0, 0x01 #output to UART
LDI x0, 0x44
AOEC6:
INPUT x4, 0x03 #check if TX buffer full
NOP
COMPARE x4, x1 #check if TX buffer full
JMPEQ AOEC6
NOP
NOP
NOP
OUTPUT x0, 0x01 #output to UART
JMP UART_OUT
NOP
NOP
NOP



MUL_OUT_END:
NOP
LDI x0, 0x45
MOEC1:
INPUT x4, 0x03 #check if TX buffer full
NOP
COMPARE x4, x1 #check if TX buffer full
JMPEQ MOEC1
NOP
NOP
NOP
OUTPUT x0, 0x01 #output to UART
LDI x0, 0x4E
MOEC2:
INPUT x4, 0x03 #check if TX buffer full
NOP
COMPARE x4, x1 #check if TX buffer full
JMPEQ MOEC2
NOP
NOP
NOP
OUTPUT x0, 0x01 #output to UART
LDI x0, 0x44
MOEC3:
INPUT x4, 0x03 #check if TX buffer full
NOP
COMPARE x4, x1 #check if TX buffer full
JMPEQ MOEC3
NOP
NOP
NOP
OUTPUT x0, 0x01 #output to UART
LDI x0, 0x4D
MOEC4:
INPUT x4, 0x03 #check if TX buffer full
NOP
COMPARE x4, x1 #check if TX buffer full
JMPEQ MOEC4
NOP
NOP
NOP
OUTPUT x0, 0x01 #output to UART
LDI x0, 0x55
MOEC5:
INPUT x4, 0x03 #check if TX buffer full
NOP
COMPARE x4, x1 #check if TX buffer full
JMPEQ MOEC5
NOP
NOP
NOP
OUTPUT x0, 0x01 #output to UART
LDI x0, 0x4C
MOEC6:
INPUT x4, 0x03 #check if TX buffer full
NOP
COMPARE x4, x1 #check if TX buffer full
JMPEQ MOEC6
NOP
NOP
NOP
OUTPUT x0, 0x01 #output to UART