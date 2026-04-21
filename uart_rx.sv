module uart_rx #(
    parameter SRC_FREQ = 76800,
    parameter BAUDRATE = 9600
)(
    input  logic       clk,      
    input  logic       rx,       
    output logic       rx_ready, 
    output logic [7:0] rx_data   
);

    localparam [1:0] 
        IDLE    = 2'b00,
        RX_DATA = 2'b01,
        STOP    = 2'b10;

    logic [1:0] state = IDLE;
    logic [2:0] bit_count = 0;
    logic       uart_clk;
    logic       ready_toggle = 0;

    clock_mul #(
        .SRC_FREQ(SRC_FREQ),
        .OUT_FREQ(BAUDRATE)
    ) u_clock_mul (
        .src_clk(clk),
        .out_clk(uart_clk)
    );

    always_ff @(posedge uart_clk) begin
        case (state)
            IDLE: begin
                if (rx == 1'b0) begin // Start bit detected
                    state <= RX_DATA;
                    bit_count <= 0;
                end
            end

            RX_DATA: begin
                // Shift in bits LSB first
                rx_data[bit_count] <= rx;
                if (bit_count == 7) begin
                    state <= STOP;
                end else begin
                    bit_count <= bit_count + 1;
                end
            end

            STOP: begin
                // Flip toggle to signal completion
                ready_toggle <= ~ready_toggle;
                state <= IDLE;
            end

            default: state <= IDLE;
        endcase
    end

    logic [2:0] sync_regs = 3'b000;
    always_ff @(posedge clk) begin
        sync_regs <= {sync_regs[1:0], ready_toggle};
        rx_ready <= sync_regs[2] ^ sync_regs[1];
    end

endmodule