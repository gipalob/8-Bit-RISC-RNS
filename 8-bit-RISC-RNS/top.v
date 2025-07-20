// Description: Top module for the 8-bit RISC RNS processor.
// Instantiates processor_top, UART, as well as any other sub-modules.

module top(
    input wire clk, 
    input wire reset,
    input wire UART_RX_in,
    output wire UART_TX_out,
    output wire PLL_LOCK
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
        .locked(PLL_LOCK)
    );

    wire [7:0] IO_read_data; // Data IN to processor 
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
    */
    wire write_to_UART, read_from_UART, TX_buffer_full, RX_data_present;
    assign write_to_UART = IO_write_strobe && (IO_port_ID == 8'h01); // Assuming UART is at port ID 0x01

    rs232_uart UART (
        .tx_data_in(IO_write_data),
        .rx_data_out(IO_read_data),
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