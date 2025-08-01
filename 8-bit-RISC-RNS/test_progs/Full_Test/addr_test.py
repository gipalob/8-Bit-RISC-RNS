addr = 0
for i in range(0, 512):
    addr += 1
    print(i, hex(addr))
    addr += 1
    print(i, hex(addr))