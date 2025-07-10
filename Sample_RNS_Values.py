# This python script generates sample values in two modular domains for numbers within the valid range.
import sys

if __name__ == "__main__":
    # if (len(sys.argv) < 3):
    #     print("Usage: python Sample_RNS_Values.py d1, d2")
    #     sys.exit(1)
        
    
    existing = []
    for i in range(33024):
        modlo = i % 129
        modhi = i % 256
        x_rec= (modlo * 16384 + modhi * 16641) % 33024
        assert x_rec == i, f"Reconstruction failed: x_rec != i... x_rec was {x_rec}"
        for item in existing:
            if item[0] == modlo and item[1] == modhi:
                print(f"Duplicate found: {item} for i={i}")
                break
        existing.append((modlo, modhi, x_rec))
        
        if modlo == 57 and modhi == 192:
            print(f"Found the value for i={i} with modlo={modlo} and modhi={modhi}")
            print(f"Reconstructed value: {x_rec}")
            
        if (modlo > modhi):
            print(f"Lower > upper at {i}")
        
    
    
    # d1 = int(sys.argv[1])
    # d2 = int(sys.argv[2])
    # # start at the first value that would not be equal to the input (overflows one of the domains)
    # valid_range = range(min(d1, d2), d1 * d2)
    
    # print(f"Integer\t\t| hex, %{d1}\t\t| hex, %{d2}\t\t| bin, %{d1}\t\t| bin, %{d2}")
    # for i in valid_range:
    #     rns1 = i % d1
    #     rns2 = i % d2
    #     print(f"{i:>5}\t| {hex(rns1):<2}\t| {hex(rns2):<2}\t| {rns1:08b}\t| {rns2:08b}")
        