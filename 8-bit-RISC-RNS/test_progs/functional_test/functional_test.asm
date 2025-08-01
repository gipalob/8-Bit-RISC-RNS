#Full function testing-
#Jumping, RNS Domain instructions (incl rolling / unrolling), I/O operations incl UART.
LDI x0, 0x11
LDI x1, 0x22
LDI x7, 0x01
ADDM m0, x0, x1
SUBM m1, x1, x0
MULM m2, x1, x1

UNRLL x2, m0
NOP
OUTPUT x2, 0x01
UNRLU x2, m0
NOP
OUTPUT x2, 0x01

UNRLL x2, m1
NOP
OUTPUT x2, 0x01
UNRLU x2, m1
NOP
OUTPUT x2, 0x01

NOP
NOP
check_buff_l1:
NOP
NOP
INPUT x4, 0x03
NOP
COMPARE x4, x3 #check TX buffer full
JMPEQ check_buff_l1 #if full, wait
NOP
NOP
NOP

UNRLL x2, m2
OUTPUT x2, 0x01
UNRLU x2, m2
OUTPUT x2, 0x01

NOP
NOP
check_buff_l2:
NOP
NOP
INPUT x4, 0x03
NOP
COMPARE x4, x7 #check TX buffer full
JMPEQ check_buff_l2 #if full, wait
NOP
NOP
NOP

LDI x0, 0x01
LDI x1, 0x01
LDI x2, 0x81 #129
LDI x6, 0xFF


#square every number in range 1-129, in modular domain outputting data to UART

mod_sqr:
MULM m0, x0, x0
UNRLL x3, m0
UNRLU x4, m0

NOP
NOP
check_buff_l3:
NOP
NOP
INPUT x5, 0x03
NOP
COMPARE x5, x7 #check TX buffer full
JMPEQ check_buff_l3 #if full, wait
NOP
NOP
NOP
NOP



OUTPUT x3, 0x01
NOP
NOP
NOP
OUTPUT x4, 0x01
ADD x0, x0, x1
NOP
COMPARE x0, x2
JMPEQ echo_loop #when we reach 129 jump to UART echo loop
#because we have no jump/return stack, we can't have a single 'buffer wait fn'
NOP
NOP
NOP
NOP
JMP mod_sqr


echo_RX_wait:
NOP
echo_loop:
INPUT x5, 0x02 #see if RX data present
NOP #NOP for safety- im unsure if forwarding will be able to fwd the data on in port
COMPARE x5, x6 #x6 is still 0xFF
JMPLT echo_RX_wait #if x5 < 0xFF, no data present, wait
echo_TX_wait:
INPUT x5, 0x03 #check if TX buffer is full
NOP #NOP for safety- im unsure if forwarding will be able to fwd the data
COMPARE x5, x6
JMPEQ echo_TX_wait #if full, wait

INPUT x5, 0x01 #read data from UART if TX buffer is not full
NOP #NOP for safety- im unsure if forwarding will be able to fwd the data on in port
OUTPUT x5, 0x01 #output data to UART
JMP echo_loop #jump back to echo loop