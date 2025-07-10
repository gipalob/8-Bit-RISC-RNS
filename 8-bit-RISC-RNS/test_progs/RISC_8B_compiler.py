import sys
J_type_opcodes = {
    "JMP": "00111",
    "JMPGT": "01110",
    "JMPLT": "01111",
    "JMPEQ": "10000",
    "JMPC": "10001"
}

R_type_opcodes = {
    "ADD": "00001",
    "SUB": "00010",
    "AND": "00011",
    "OR": "00100",
    "NOT": "00101",
    "SHL": "00110",
    "RLOAD": "01000",
    "RSTORE": "01001",
    "ANDBIT": "01010",
    "ORBIT": "01011",
    "NOTBIT": "01100",
    "COMPARE": "01101",
    "ADDM": "10011",
    "SUBM": "10100",
    "MULM": "10101",
    "UNRLL": "10111",
    "UNRLU": "11000",
    "RLLM": "11001"
}

I_type_opcodes = {
    "LDI": "10010"
}



num_labels = 0 #need to count labels to be able to accurately convert them to addresses
label_addresses = {}



def get_opcode(operation: str) -> str:
    op = operation.upper()
    if op in J_type_opcodes.keys():
        return J_type_opcodes[op], 'J'
    elif op in R_type_opcodes.keys():
        return R_type_opcodes[op], 'R'
    elif op in I_type_opcodes.keys():
        return I_type_opcodes[op], 'I'
    else:
        return None, None



def conv_hex(inst_line: int, bin_instr: str) -> str:
    if len(bin_instr) % 4 != 0:
        raise ValueError(f"Binary instruction length must be a multiple of 4:\n{bin_instr}\nAt line {inst_line}")
    
    hex_instr = hex(int(bin_instr, 2))[2:].upper()
    return hex_instr.zfill(len(bin_instr) // 4)



def get_reg_bin(reg_str: str, src_reg: bool = False) -> str:
    reg_bin = ""
    
    if reg_str[0].upper() == 'X':
        if src_reg:
            reg_bin += '0'
        
        reg_bin += bin(int(reg_str[1:])).replace('0b', '').zfill(3)
        
    elif reg_str[0].upper() == 'M':
        if src_reg:
            reg_bin += '1'
        reg_bin += bin(int(reg_str[1:])).replace('0b', '').zfill(3)
    print(f"Src_reg: {src_reg}, reg_str {reg_str} -> {reg_bin}")
    return reg_bin



def get_I_bin(instruction: list, opcode: str = None): 
    """
    Converts an I-type instruction to its binary representation.
    """
    if len(instruction) != 3:
        raise ValueError("I-type instruction must have 3 parts: opcode, destination, and immediate value.")
    
    destreg = get_reg_bin(instruction[1], src_reg=False)
    
    if instruction[2].startswith("0x"):
        imm = bin(int(instruction[2][2:], 16))[2:].zfill(8)
    elif instruction[2].isdigit():
        imm = bin(int(instruction[2])).zfill(8)
    
    
    return f"{opcode}{destreg}{imm}"



def get_J_bin(instruction: list, opcode: str = None):
    if len(instruction) != 2:
        raise ValueError("J-type instruction must have 2 parts: opcode and address.")
    
    # We expect the jump target to be a label
    j_targ = instruction[1].strip().upper()
    addr = label_addresses.get(j_targ, None)
    
    if addr is None:
        raise ValueError(f"Label '{j_targ}' not defined before use.")


    return f"{opcode}0{addr}"



def get_R_bin(instruction: list, opcode: str = None):
    """
    Converts an R-type instruction to its binary representation.
    """
    if len(instruction) not in (3, 4):
        raise ValueError("R-type instruction must have at least 3 parts: opcode, rd, rs1, rs2 ")
    
    if (instruction[0].upper() == "COMPARE"): 
        rs1 = get_reg_bin(instruction[1], src_reg=True)
        rs2 = get_reg_bin(instruction[2], src_reg=True)
        destreg = "000"
    elif ("UNRL" in instruction[0].upper()):
        rs1 = get_reg_bin(instruction[2], src_reg=True)
        rs2 = "0000"
        destreg = get_reg_bin(instruction[1], src_reg = False)
        
    else:
        rs1 = get_reg_bin(instruction[2], src_reg=True)
        rs2 = get_reg_bin(instruction[3], src_reg=True)
        destreg = get_reg_bin(instruction[1], src_reg=False)
    
    return f"{opcode}{destreg}{rs2}{rs1}"



def get_inst_bin(instruction: str, inst_line: int) -> str:
    """
    Converts an instruction to its binary (hexadecimal) representation.
    """
    print(f"instruction {inst_line}: {instruction}")
    instruction = instruction.replace(',', ' ')
    parts = [part.strip() for part in instruction.split()]
    
    if parts[0].upper() == "NOP":
        return "0000"
    else:
        opcode, optype = get_opcode(parts[0])
        
        if opcode == None and optype == None:
            raise ValueError(f"Unknown instruction: {parts[0]}")
        
        if optype == 'I':
            inst = get_I_bin(parts, opcode)
        elif optype == 'J':
            inst = get_J_bin(parts, opcode)
        elif optype == 'R':
            inst = get_R_bin(parts, opcode)
        
    print(f"Binary instruction: {inst}\n\n")
    return conv_hex(inst_line, inst)



if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python RISC_8B_compiler.py <source_file>")
        sys.exit(1)


    source_file = sys.argv[1]
    dest_file = sys.argv[2]

    try:
        hex_prog = []
        file_lines = []
        label_lines = []
        
        # This is the 'pre-processing' loop- 
            # Checking for labels + storing their addresses,
            # and also checking for in-line comments. 
        for index, inst_line in enumerate(open(source_file, 'r').readlines()):
            inst_line = inst_line.strip()
            # Here, we're checking for labels and storing their addresses
            if not inst_line:
                continue
            elif inst_line.strip().endswith(':'):
                label_lines.append((index, inst_line))
                label = inst_line.strip()[:-1].upper()
                num_labels += 1
                if label not in label_addresses:
                    label_addresses[label] = bin(index + 1 - num_labels)[2:].zfill(10)
            # Now, check for comments. First, the 'easy' way
            elif (inst_line.startswith('#')): 
                continue
            else:
                found_comment = False
                comment_start = 0
                for i, char in enumerate(inst_line):
                    if char == '#':
                        found_comment = True
                        comment_start = i
                        break
                if found_comment:
                    inst_line = inst_line[:comment_start].strip()
                    if not inst_line: # just for safety
                        continue
                    
                file_lines.append((inst_line, index)) # to maintain the original line numbers
                        
        for (inst_line, index) in file_lines:
            hex_prog.append(get_inst_bin(inst_line, index))
            
        
        open(dest_file, 'w').write('\n'.join(hex_prog))
        
    except FileNotFoundError:
        print(f"Error: The file '{source_file}' does not exist.")
        sys.exit(1)