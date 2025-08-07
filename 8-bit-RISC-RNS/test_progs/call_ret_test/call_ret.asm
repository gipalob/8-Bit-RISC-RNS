#Testing JMP RA instruction. Effectively the same program as Full_Test.asm, but modified to JMP based on stack.
#Full test of HW functions- RNS arithmetic, I/O, Expanded data memory.
LDI x0, 0x00
LDI x1, 0x01
ADDM m2, x0, x1 #set m2 to 1
LDI x5, 0xFF
LDI x6, 0x00 #mem addr [15:8]
LDI x7, 0x00 #mem addr [7:0]
JMP ADD_LOOP
NOP





IT_MEM_UPPER:
NOP
ADD x6, x6, x1
LDI x7, 0x00
JR RA
NOP
#STORE_TO_MEM fn expects value to be stored to memory to be placed in reg x3. 
#stores no pre-existing reg data to mem, expects x6/x7 to not be modified by callee.
#trusts that x5 will hold 0xFF.
STORE_TO_MEM:
NOP
ADD x7, x7, x1 #increment mem addr
RSTORE x3, x6, x7
COMPARE x7, x5 
JMPLT STORE_RET
NOP
CALL IT_MEM_UPPER
NOP
STORE_RET:
NOP
JR RA
NOP
#LOAD_FROM_MEM expects x6/x7 to not be modified by callee.
#Will load data at {x6, x7} into x3.
LOAD_FROM_MEM:
NOP
ADD x7, x7, x1
RLOAD x3, x6, x7
COMPARE x7, x5
JMPLT LOAD_RET
NOP
CALL IT_MEM_UPPER
NOP
LOAD_RET:
NOP
JR RA
NOP
NOP
NOP


#add loop adds numbers to themselves a bunch and then stores to mem
ADD_LOOP: 
NOP
ADDM m0, m2, m2 # m0 = m2 + m2
ADDM m2, m2, x1 # m2++
UNRLU x3, m0
CALL STORE_TO_MEM
NOP #we return to here on STORE_TO_MEM return
NOP
UNRLL x3, m0
CALL STORE_TO_MEM
NOP #we return to here on STORE_TO_MEM return
NOP
LDI x4, 0x06
COMPARE x6, x4
JMPLT ADD_LOOP
NOP
#now we've done add storing to mem. output via UART now.
ADD x2, x7, x0 # set x2 to {highest ADD_LOOP address}[7:0]
LDI x5, 0xFF
LDI x6, 0x00 #reset mem addr
LDI x7, 0x00 #reset mem addr


UART_OUT:
NOP
INPUT x4, 0x03
COMPARE x4, x1 #check if TX buffer full
JMPEQ UART_OUT
NOP
CALL LOAD_FROM_MEM
NOP
NOP
OUTPUT x3, 0x01 #output to UART
LDI x4, 0x06
COMPARE x6, x4
JMPLT UART_OUT
NOP
#We still have one last RNS solution from the add loop to output at 0x0200. Do that first.


ADD_OUT_END:
NOP
INPUT x4, 0x03
COMPARE x4, x1 #check if TX buffer full
JMPEQ ADD_OUT_END
NOP
COMPARE x7, x2
JMPGT ADD_OUT_PRINT #UART out loops until at the end of the loop it sees that addr[15:8] is 0x06- not necessarily until all outputs have been sent to UART. ADD_OUT_END checks for that
NOP
CALL LOAD_FROM_MEM
NOP
NOP
OUTPUT x3, 0x01
JMP ADD_OUT_END
NOP

ADD_OUT_PRINT:
NOP
LDI x0, 0x45
AOEC1:
NOP
INPUT x4, 0x03 #check if TX buffer full
NOP
COMPARE x4, x1 #check if TX buffer full
JMPEQ AOEC1
NOP
OUTPUT x0, 0x01 #output to UART
LDI x0, 0x4E
AOEC2:
NOP
INPUT x4, 0x03 #check if TX buffer full
COMPARE x4, x1 #check if TX buffer full
JMPEQ AOEC2
NOP
OUTPUT x0, 0x01 #output to UART
LDI x0, 0x44
AOEC3:
NOP
INPUT x4, 0x03 #check if TX buffer full
COMPARE x4, x1 #check if TX buffer full
JMPEQ AOEC3
NOP
OUTPUT x0, 0x01 #output to UART
LDI x0, 0x41
AOEC4:
NOP
INPUT x4, 0x03 #check if TX buffer full
COMPARE x4, x1 #check if TX buffer full
JMPEQ AOEC4
NOP
OUTPUT x0, 0x01 #output to UART
LDI x0, 0x44
AOEC5:
NOP
INPUT x4, 0x03 #check if TX buffer full
COMPARE x4, x1 #check if TX buffer full
JMPEQ AOEC5
NOP
OUTPUT x0, 0x01 #output to UART
LDI x0, 0x44
AOEC6:
NOP
INPUT x4, 0x03 #check if TX buffer full
COMPARE x4, x1 #check if TX buffer full
JMPEQ AOEC6
NOP
OUTPUT x0, 0x01 #output to UART
NOP
UART_ECHO:
NOP
INPUT x4, 0x02 #check RX_data_present
COMPARE x4, x1
JMPLT UART_ECHO #if RX_data_present < 00...01, keep waiting
NOP
INPUT x2, 0x01 #else, read UART RX data
NOP
UART_ECHO_CHECK:
NOP
INPUT x4, 0x03 #check TX_buffer_full
COMPARE x4, x1
JMPEQ UART_ECHO_CHECK #if TX buffer full, wait
NOP
OUTPUT x2, 0x01 #echo back RX to TX
JMP UART_ECHO