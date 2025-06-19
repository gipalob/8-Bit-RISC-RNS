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
    "COMPARE": "01101"
}

I_type_opcodes = {
    "LDI": "10010"
}

NUM_REGISTERS = 7


def get_I_bin(instruction: list): 
    """
    Converts an I-type instruction to its binary representation.
    """
    if len(instruction) != 3:
        raise ValueError("I-type instruction must have 3 parts: opcode, destination, and immediate value.")
    
    opcode = I_type_opcodes.get(instruction[0])
    destreg = instruction[1]
    
    if destreg > NUM_REGISTERS:
        raise ValueError(f"Destination register {destreg} exceeds the maximum of {NUM_REGISTERS}.")
    
    if instruction[2].startswith("0x"):
        imm = bin(int(instruction[2], 16))[2:].zfill(8)
    elif instruction[2].isdigit():
        imm = bin(int(instruction[2])).zfill(8)
    
    
    return f"{opcode}{destreg}{imm}"

def get_R_bin(instruction: list):
    """
    Converts an R-type instruction to its binary representation.
    """
    if len(instruction) not in (3, 4):
        raise ValueError("R-type instruction must have at least 3 parts: opcode, rd, rs1, rs2 ")
    
    opcode = R_type_opcodes.get(instruction[0])
    
    rs1 = bin(int(instruction[2])).zfill(3)
    
    rs2 = bin(int(
        instruction[3] if len(instruction) == 4 else "0"
    )).zfill(3)
    
    destreg = bin(int(instruction[1])).zfill(3)
    
    if rs1 > NUM_REGISTERS or rs2 > NUM_REGISTERS or destreg > NUM_REGISTERS:
        raise ValueError(f"Register {rs1} or {rs2} or {destreg} exceeds the maximum of {NUM_REGISTERS}.")
    
    return f"{opcode}{destreg}0{rs2}0{rs1}"


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python RISC_8B_compiler.py <source_file>")
        sys.exit(1)

    source_file = sys.argv[1]

    try:
        with open(source_file, 'r') as file:
            source_code = file.read()
            # Here you would typically parse the source code and compile it
            print(f"Compiling {source_file}...")
            # Placeholder for compilation logic
            print("Compilation successful!")
    except FileNotFoundError:
        print(f"Error: The file '{source_file}' does not exist.")
        sys.exit(1)