import sys
from typing import TextIO
from math import floor

class ASMtoBin:
    def get_opcode(self, operation: str) -> str:
        op = operation.upper()
        if op in self.J_type_opcodes.keys():
            return self.J_type_opcodes[op], 'J'
        elif op in self.R_type_opcodes.keys():
            return self.R_type_opcodes[op], 'R'
        elif op in self.I_type_opcodes.keys():
            return self.I_type_opcodes[op], 'I'
        else:
            return None, None


    def get_hex_instr(self, bin_instr: str) -> str:
        hex_instr = hex(int(bin_instr, 2))[2:].upper()
        return hex_instr.zfill(len(bin_instr) // 4)


    def get_reg_bin(self, reg_str: str, src_reg: bool = False) -> str:
        reg_bin = ""
        
        if reg_str[0].upper() == 'X':
            if src_reg:
                reg_bin += '0'
            
            reg_bin += bin(int(reg_str[1:])).replace('0b', '').zfill(3)
            
        elif reg_str[0].upper() == 'M':
            if src_reg:
                reg_bin += '1'
            reg_bin += bin(int(reg_str[1:])).replace('0b', '').zfill(3)
        return reg_bin


    def get_I_bin(self, instruction: list, opcode: str = None): 
        """
        Converts an I-type instruction to its binary representation.
        """
        if len(instruction) != 3:
            raise ValueError("I-type instruction must have 3 parts: opcode, destination, and immediate value.")
        
        destreg = self.get_reg_bin(instruction[1], src_reg=False)
        
        if instruction[2].startswith("0x"):
            imm = bin(int(instruction[2][2:], 16))[2:].zfill(8)
        elif instruction[2].isdigit():
            imm = bin(int(instruction[2])).zfill(8)
        
        
        return f"{opcode}{destreg}{imm}"


    def get_J_bin(self, instruction: list, opcode: str = None):
        if len(instruction) != 2:
            raise ValueError("J-type instruction must have 2 parts: opcode and address.")
        
        # We expect the jump target to be a label
        j_targ = instruction[1].strip().upper()
        addr = self.label_addresses.get(j_targ, None)
        
        if addr is None:
            raise ValueError(f"Label '{j_targ}' not defined before use.")


        return f"{opcode}0{addr}"


    def get_R_bin(self, instruction: list, opcode: str = None):
        """
        Converts an R-type instruction to its binary representation.
        """
        if len(instruction) not in (3, 4):
            raise ValueError("R-type instruction must have at least 3 parts: opcode, rd, rs1, rs2 ")
        
        if (instruction[0].upper() == "COMPARE"): 
            rs1 = self.get_reg_bin(instruction[1], src_reg=True)
            rs2 = self.get_reg_bin(instruction[2], src_reg=True)
            destreg = "000"
        elif ("UNRL" in instruction[0].upper()):
            rs1 = self.get_reg_bin(instruction[2], src_reg=True)
            rs2 = "0000"
            destreg = self.get_reg_bin(instruction[1], src_reg = False)
            
        else:
            rs1 = self.get_reg_bin(instruction[2], src_reg=True)
            rs2 = self.get_reg_bin(instruction[3], src_reg=True)
            destreg = self.get_reg_bin(instruction[1], src_reg=False)
        
        return f"{opcode}{destreg}{rs2}{rs1}"


    def get_inst_bin(self, instruction: str, inst_line: int) -> str:
        """
        Converts an instruction to its binary (hexadecimal) representation.
        """
        instruction = instruction.replace(',', ' ')
        parts = [part.strip() for part in instruction.split()]
        
        if parts[0].upper() == "NOP":
            return "0000000000000000"
        else:
            opcode, optype = self.get_opcode(parts[0])
            
            if opcode == None and optype == None:
                raise ValueError(f"Unknown instruction: {parts[0]}")
            
            if optype == 'I':
                inst = self.get_I_bin(parts, opcode)
            elif optype == 'J':
                inst = self.get_J_bin(parts, opcode)
            elif optype == 'R':
                inst = self.get_R_bin(parts, opcode)
            
        return inst
    
    
    def rm_labels_comments(self):
        for index, inst_line in enumerate(self.fileobj.readlines()):
            inst_line = inst_line.strip()
            # Here, we're checking for labels and storing their addresses
            if not inst_line:
                continue
            elif inst_line.strip().endswith(':'):
                self.label_lines.append((index, inst_line))
                label = inst_line.strip()[:-1].upper()
                num_labels += 1
                if label not in self.label_addresses:
                    self.label_addresses[label] = bin(index + 1 - num_labels)[2:].zfill(10)
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
                    
                self.file_lines.append((inst_line, index)) # to maintain the original line numbers
    
    
    def getHexProg(self) -> list:
        return self.hex_prog
    
    
    def getBinProg(self) -> list:
        return self.bin_prog

    
    def __init__(self, fileobj: TextIO):
        '''
        Taking a file object as input, this class will take the ASM written for the RISC-RNS 8b processor,
        remove labels and comments, and convert the instructions to binary.
        A list of the binary instructions can be obtained with ASMtoBin.getBinProg(),
        and a list of the hexadecimal instructions can be obtained with ASMtoBin.getHexProg().
        ''' 
        self.fileobj = fileobj
        self.file_lines = []
        self.label_lines = []
        self.num_labels = 0
        self.label_addresses = {}
        self.hex_prog = []
        self.bin_prog = []
        
        self.J_type_opcodes = {
            "JMP": "00111",
            "JMPGT": "01110",
            "JMPLT": "01111",
            "JMPEQ": "10000",
            "JMPC": "10001"
        }
        self.R_type_opcodes = {
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
        self.I_type_opcodes = {
            "LDI": "10010"
        }
        
        self.rm_labels_comments()
        
        for (inst_line, index) in self.file_lines:
            bin_line = self.get_inst_bin(inst_line, index)
            self.bin_prog.append(bin_line)
            hex_line = self.get_hex_instr(bin_line)
            self.hex_prog.append(hex_line)
            
        self.fileobj.close()
        
        
        
def hexToInt(num: int, max_int_val:int, hex_addr_len:int):
    if max_int_val < num:
        raise ValueError(f"convHex: Value {num} exceeds maximum value of {max_int_val}")
    
    return format(num, '0{}X'.format(hex_addr_len))        
        
        

class BinToV:       
    def getCaseStatement(self) -> list:
        curInst = 0
        for instAddr in range(0, len(self.hexInsts)):
            curInst = instAddr
            
            if len(self.hexInsts[instAddr]) != 4:
                raise ValueError(f"Instruction at address {instAddr} is not 4 hex digits long: {self.hexInsts[instAddr]}")
            
            self.case_lines.insert(
                self.start_case_insert + instAddr,
                f"\t\t10'h{hexToInt(instAddr, self.max_int_val, self.hex_addr_len)}: instruction <= 16'h{self.hexInsts[instAddr]};"
            )
            
        #for when len(hexInsts) < 2**prog_ctr_wid
        for instAddr in range(curInst + 1, self.max_int_val):
            self.case_lines.insert(
                self.start_case_insert + instAddr,
                f"\t\t10'h{hexToInt(instAddr, self.max_int_val, self.hex_addr_len)}: instruction <= 16'h0000;"
            )
            
        return self.case_lines
        
        
    def getVerilogLines(self) ->list:
        """
        Get a list of the lines for the verilog file.
        """
        if len(self.case_lines) == self.default_case_len:
            self.getCaseStatement()
        
        verilog_lines = self.header.copy()
        verilog_lines.extend(self.case_lines)
        verilog_lines.extend(self.footer)
        
        return verilog_lines
        
    
    def __init__(self, hexInsts: list, prog_ctr_wid: int = 10):
        '''
        This class will take a list of hex-encoded binary instructions and place them into a hard-coded verilog file,
        'Instr_Mem.v', containing module Instr_Mem.
        The verilog module will have inputs / outputs / parameters:
            parameter PROG_CTR_WID (predef 10)
            input [PROG_CTR_WID-1:0] prog_ctr
            output reg [15:0] instruction
            
        Instructions are placed within a case statement, which should be placed within a LUT on synthesis.
        '''
        self.hex_addr_len = (floor(prog_ctr_wid / 4) + 1) if (prog_ctr_wid % 4) else (prog_ctr_wid / 4)
        self.max_int_val = 2 ** prog_ctr_wid
        
        self.prog_ctr_wid = prog_ctr_wid
        self.hexInsts = hexInsts 
        
        self.header = [
            f"module Instr_Mem #(parameter PROG_CTR_WID = {prog_ctr_wid}) (",
            f"\tinput [PROG_CTR_WID-1:0] prog_ctr,",
            f"\toutput reg [15:0] instruction",
            f");"
        ]
        self.case_lines = [
            f"always @(*) begin",
            f"\tcase (prog_ctr)",
            f"\t\tdefault: instruction <= 16'h0000;",
            f"\tendcase",
            f"end"
        ]
        self.start_case_insert = 2
        self.default_case_len = len(self.case_lines)
        self.footer = [
            f"endmodule"
        ]
        
        
         
        
        
        
        

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("""\033[1;31mUsage: \033[22mpython ASMtoV.py <input_asm_file> <output_verilog_file>\033[0m
        \033[1;32mAdditional optional arguments:\033[0m
        \033[32m--pc_wid <prog_ctr_width>\033[0
        \tSpecify a program counter width (default: 10)
        \033[32m--bin_file_out <binary_file || 'print'>\033[0
        \tSpecify a file to output, or print to console, the binary instructions for viewing (default: None)\033[0m
        """)
        sys.exit(1)
    
    try: 
        source_file = open(sys.argv[1], 'r')
    except:
        print(f"\033[1;31mError: Could not open source file {sys.argv[1]}\033[0m")
        sys.exit(1)

    try:
        dest_file = open(sys.argv[2], 'w')
    except:
        print(f"\033[1;31mError: Could not open destination file {sys.argv[2]}\033[0m")
        sys.exit(1)
        
    pc_width = 10
    print_bin = False
    bin_fout = None

    if (len(sys.argv) > 3):
        if ("--pc_wid" in sys.argv):
            argidx = sys.argv.index("--pc_wid")
            pc_width = int(sys.argv[argidx + 1])
            
        if ("--bin_file_out" in sys.argv):
            argidx = sys.argv.index("--bin_file_out")
            if (sys.argv[argidx + 1] == "print"):
                print_bin = True
            else:
                bin_fout = open(sys.argv[argidx + 1], 'w')

        #can add handling for other options here later
    
    asm_to_bin = ASMtoBin(source_file)
    hex_prog = asm_to_bin.getHexProg()
    
    bin_to_v = BinToV(hex_prog, prog_ctr_wid=pc_width)
    verilog_module_lines = bin_to_v.getVerilogLines()
    
    dest_file.writelines([line + '\n' for line in verilog_module_lines])
    dest_file.close()
    print(f"\033[1;32mVerilog module written to {sys.argv[2]}\033[0m")
    
    if print_bin:
        print(f"\n\033[1;32mBinary instructions:\033[0m")
        bin_prog = asm_to_bin.getBinProg()
        hex_addr_gen = (hexToInt(i, bin_to_v.max_int_val, bin_to_v.hex_addr_len) for i in range(len(bin_prog)))
        
        [print(f"{pc_width}'h{inst_addr}: {inst}") for (inst, inst_addr) in zip(bin_prog, hex_addr_gen)]
        
    if bin_fout:
        bin_fout.writelines([f"{inst}\n" for inst in asm_to_bin.getBinProg()])
        bin_fout.close()
        print(f"\033[1;32mBinary instructions written to {sys.argv[3]}\033[0m")