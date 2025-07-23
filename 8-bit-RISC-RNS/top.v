// Description: Top module for the 8-bit RISC RNS processor.
// Instantiates processor_top, UART, as well as any other sub-modules.

module top(
    input wire clk, 
    input wire reset,
    input wire UART_RX_in,
    output wire UART_TX_out,
    output wire [1:0] led
);
    // Parameters
    parameter NUM_DOMAINS = 2; // Number of RNS domains; Integer domain remains.
    parameter [9 * NUM_DOMAINS - 1 : 0] MODULI = {9'd129, 9'd256}; // moduli for RNS domains. 9 bits to be sure... could be optimized?
    
    /*
        The hardware targeted for testing is a Digilent Cmod A7-35T. The Cmod's oscillator is only 12MHz,
    */
    wire clk100; // 100MHz clock output from clock wizard
    clk_wiz_0 clock_wizard(
        .clk_in1(clk),
        .reset(reset),
        .clk_out1(clk100),
        .locked(led[0])
    );

    reg [7:0] IO_read_data; // Data IN to processor 
    wire [7:0] IO_port_ID; // Port ID for I/O operations
    wire [7:0] IO_write_data; // Data OUT from processor
    wire IO_write_strobe; // Write strobe signal
    wire IO_read_strobe; // Effectively, processor read ACK
    processor_top #(NUM_DOMAINS, MODULI) processor (
        .clk100(clk100),
        .reset(reset),
        .IO_read_data(IO_read_data),
        .IO_port_ID(IO_port_ID),
        .IO_write_data(IO_write_data),
        .IO_write_strobe(IO_write_strobe),
        .IO_read_strobe(IO_read_strobe)
    );

    /*
        This UART implementation comes from material provided in CDA 4203, Computer System Design - Sp25, Kermani.
        The IO implementation on the processor level mimics how IO functions on the PicoBlaze.
        Port 0x01: UART Input / Output
        Port 0x02: Processor input, RX data present
        Port 0x03: Processor input, TX buffer full
    */
    wire [7:0] UART_TX_data, UART_RX_data;
    wire write_to_UART, TX_buffer_full, RX_data_present;
    reg read_from_UART;
    assign write_to_UART = (IO_write_strobe == 1'b1) && (IO_port_ID == 8'h01); // UART is at port ID 0x01
    assign UART_TX_data = (IO_port_ID == 8'h01 && IO_write_strobe == 1'b1) ? IO_write_data : 8'b0; // Data to be sent over UART

    assign led[1] = IO_read_strobe;

    always @(posedge clk100) begin
        read_from_UART <= 1'b0;
        if (reset) begin
            IO_read_data <= 8'b0; // Reset IO read data
        end else begin
            if (IO_read_strobe == 1'b1) 
            begin
                case (IO_port_ID)
                    8'h01: begin
                        IO_read_data <= UART_RX_data; // Read data from UART if port ID matches
                        read_from_UART <= 1'b1;
                    end
                    8'h02: IO_read_data <= RX_data_present ? 8'b1 : 8'b0; // Indicate if RX data is present
                    8'h03: IO_read_data <= TX_buffer_full ? 8'b1 : 8'b0; // Indicate if TX buffer is full
                    default: IO_read_data <= 8'b0; 
                endcase
            end
        end
    end
    

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
        .clk(clk100)
    );
endmodule