#This script will take the raw bytes output from a serial console log and verify their arithmetic correctness.
#Written to currently target UART output from Full_Test.asm
import sys
from typing import TextIO

def get_file_bytes(file: TextIO) -> list:
    file.seek(0)
    return list(file.read())

def split_list(bytelist: list, splits: list = ['ENDADD', 'ENDMUL']) -> list:
    split_lists = []
    len_bytelist = len(bytelist)
    ord_splits = [[ord(ch) for ch in split] for split in splits]
    
    for split in ord_splits:
        split_len = len(split)
        for i in range(len_bytelist - split_len + 1):
            if bytelist[i:i + split_len] == split:
                split_lists.append(bytelist[:i])
                bytelist = bytelist[i + split_len:]
                break
            
    return split_lists

def get_rns_pairs(split_list: list) -> list:
    add_and_mul_pairs = []
    for split in split_list:
        pair_set = []
        for i in range(0, len(split), 2):
            if i + 1 < len(split):
                pair_set.append((split[i], split[i + 1]))
        
        if pair_set:
            add_and_mul_pairs.append(pair_set)
            
    return add_and_mul_pairs

def print_add_pairs(add_pairs: list):
    print(f"Index\t|Intended Op \t\t| %129 binary  | %129 decimal  | %256 binary   | %256 decimal  | Reconstructed value")
    for i, pair in enumerate(add_pairs):
        mod256_int = pair[0]
        mod256_bin = format(mod256_int, '08b')
        mod129_int = pair[1]
        mod129_bin = format(mod129_int, '08b')
        rec_val = (mod129_int * 16384 + mod256_int * 16641) % 33024

        print(f"{i+1}\t |{i+1}+{i+1}={(i+1) + (i+1)} \t\t| {mod129_bin}\t| {mod129_int}\t\t| {mod256_bin}\t| {mod256_int}\t\t| {rec_val}")

def print_mul_pairs(mul_pairs: list):
    print(f"Index\t|Intended Op \t\t| %129 binary  | %129 decimal  | %256 binary   | %256 decimal  | Reconstructed value")
    for i, pair in enumerate(mul_pairs):
        mod256_int = pair[0]
        mod256_bin = format(mod256_int, '08b')
        mod129_int = pair[1]
        mod129_bin = format(mod129_int, '08b')
        rec_val = (mod129_int * 16384 + mod256_int * 16641) % 33024
        
        print(f"{i+1}\t|{i+1}*{i+1} = {(i+1) * (i+1)} \t\t| {mod129_bin}\t| {mod129_int}\t\t| {mod256_bin}\t| {mod256_int}\t\t| {rec_val}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python console_verify.py <console_log_file>")
        sys.exit(1)
    
    try:
        in_file = open(sys.argv[1], 'rb')
        file_bytes = get_file_bytes(in_file)
        in_file.close()
        
        split_lists = split_list(file_bytes)
        rns_pairs = get_rns_pairs(split_lists)
        
        print(f"\n\n\nAddition values:")
        print_add_pairs(rns_pairs[0])
        print(f"\n\n\nMultiplication values:")
        print_mul_pairs(rns_pairs[1])
        
    except Exception as e:
        print(f"Error opening file: {e}")
        sys.exit(1)