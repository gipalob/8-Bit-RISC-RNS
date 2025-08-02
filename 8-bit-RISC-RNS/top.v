// Description: Top module for the 8-bit RISC RNS processor.
// Instantiates processor_top, UART, as well as any other sub-modules.

module top(
    input wire clk, 
    input wire [1:0] btn,
    input wire UART_RX_in,
    output wire UART_TX_out,
    output [1:0] led,
    output [22:1] pio
);
    // Parameters
    parameter NUM_DOMAINS = 2; // Number of RNS domains; Integer domain remains.
    parameter PROG_CTR_WID = 10;
    parameter [9 * NUM_DOMAINS - 1 : 0] MODULI = {9'd129, 9'd256}; // moduli for RNS domains. 9 bits to be sure... could be optimized?
    
    /*
        The hardware targeted for testing is a Digilent Cmod A7-35T. The Cmod's oscillator is only 12MHz,
    */

    wire reset;
    assign reset = btn[0];

    wire [7:0] IO_read_data; // Data IN to processor 
    wire [7:0] IO_port_ID; // Port ID for I/O operations
    wire [7:0] IO_write_data; // Data OUT from processor
    wire IO_write_strobe; // Write strobe signal
    wire IO_read_strobe; // Effectively, processor read ACK
    wire [9:0] pc_copy;
    wire [4:0] opcode;
    wire [15:0] instruction; // Instruction fetched from memory

    wire [7:0] UART_RX_data;
    wire [7:0] UART_TX_data; 
    wire TX_buffer_full, RX_data_present, write_to_UART;
    wire read_from_UART;
    
    
    // PIO assigns for debugging w/ AD2
    assign pio[10:1] = pc_copy;


    processor_top #(PROG_CTR_WID, NUM_DOMAINS, MODULI) processor (
        .clk(clk),
        .reset(reset),
        .IO_read_data(IO_read_data),
        .IO_port_ID(IO_port_ID),
        .IO_write_data(IO_write_data),
        .IO_write_strobe(IO_write_strobe),
        .IO_read_strobe(IO_read_strobe),
        .pc_copy(pc_copy),
        .opcode(opcode),
        .inst_dup(instruction)
    );
    rs232_uart UART (
        .tx_data_in(UART_TX_data),
        .rx_data_out(UART_RX_data),
        .write_tx_data(write_to_UART),
        .tx_buffer_full(TX_buffer_full),
        .read_rx_data_ack(read_from_UART),
        .rx_data_present(RX_data_present),
        .rs232_tx(UART_TX_out),
        .rs232_rx(UART_RX_in),
        .reset(reset),
        .clk(clk)
    );
    
    assign led[1] = RX_data_present;
    //assign led[0] = TX_buffer_full;

    /*
        This UART implementation comes from material provided in CDA 4203, Computer System Design - Sp25, Kermani.
        The IO implementation on the processor level mimics how IO functions on the PicoBlaze.
        Port 0x01: UART Input / Output
        Port 0x02: Processor input, RX data present
        Port 0x03: Processor input, TX buffer full
    */
    
    
    //for write
    assign write_to_UART = (IO_write_strobe == 1'b1 && IO_port_ID == 8'h01) ? 1'b1 : 1'b0;
    assign UART_TX_data = (IO_write_strobe == 1'b1 && IO_port_ID == 8'h01) ? IO_write_data : 8'b0;

    // always @(posedge clk) begin
    //     write_to_UART <= 1'b0;
    //     if (IO_write_strobe == 1'b1) begin
    //         case (IO_port_ID)
    //             8'h01: 
    //                 begin
    //                     write_to_UART <= 1'b1;
    //                     UART_TX_data <= IO_write_data;
    //                 end
    //             default: 
    //                 begin
    //                     UART_TX_data <= 8'b0;
    //                 end  
    //         endcase
    //     end
    // end

    assign read_from_UART = (IO_read_strobe == 1'b1 && IO_port_ID == 8'h01) ? 1'b1 : 1'b0;
    assign IO_read_data = (IO_read_strobe == 1'b1) ? 
        (IO_port_ID == 8'h01 ? UART_RX_data : 
        (IO_port_ID == 8'h02 ? {7'b0, RX_data_present} : 
        (IO_port_ID == 8'h03 ? {7'b0, TX_buffer_full} : 8'b0))) : 8'b0;


    // always @(posedge clk) begin
    //     read_from_UART <= 1'b0;

    //     if (reset == 1'b1) begin
    //         IO_read_data <= 8'b0; // Reset IO read data
    //     end else begin
    //         read_from_UART <= 1'b0;
            
    //         if (IO_read_strobe == 1'b1) 
    //         begin
    //             case (IO_port_ID)
    //                 8'h01: 
    //                     begin
    //                         IO_read_data <= RX_data_present ? UART_RX_data : 8'b0; // Read data from UART if port ID matches
    //                         read_from_UART <= 1'b1;
    //                     end
    //                 8'h02: 
    //                     begin
    //                         IO_read_data <= {7'b0, RX_data_present}; // Indicate if RX data is present
    //                     end
    //                 8'h03: 
    //                     begin
    //                         IO_read_data <= {7'b0, TX_buffer_full}; // Indicate if TX buffer is full
    //                     end
    //                 default:
    //                     begin
    //                         IO_read_data <= 8'b0;
    //                     end
    //             endcase
    //         end
    //     end
    // end
endmodule