module top_module (
    input [7:0] A_in,
    input [7:0] B_in,
    input operands_val,
    input Clk, Rst, ack,
    output [7:0] gcd_out,
    output gcd_valid
);

    wire [1:0] A_MUX_sel;
    wire B_MUX_sel, A_en, B_en, A_lt_B, B_eq_0;
  

    datapath d1 (
        .A_in(A_in),
        .B_in(B_in),
        .Clk(Clk),
        .A_MUX_sel(A_MUX_sel),
        .B_MUX_sel(B_MUX_sel),
        .A_en(A_en),
        .B_en(B_en),
        .gcd_out(gcd_out),
        .A_lt_B(A_lt_B),
        .B_eq_0(B_eq_0)
    );

    controlpath c1 (
        .ack(ack),
        .Rst(Rst),
        .Clk(Clk),
        .operands_val(operands_val),
        .A_lt_B(A_lt_B),
        .B_eq_0(B_eq_0),
        .A_MUX_sel(A_MUX_sel),
        .B_MUX_sel(B_MUX_sel),
        .gcd_valid(gcd_valid),
        .A_en(A_en),
        .B_en(B_en)
    );

endmodule

// Datapath
module datapath (
    input [7:0] A_in, B_in,
    input Clk,
    input [1:0] A_MUX_sel,
    input B_MUX_sel, A_en, B_en,
    output [7:0] gcd_out,
    output A_lt_B, B_eq_0
);

    wire [7:0] A_MUX_out, B_MUX_out;
    reg [7:0] A, B;
    wire [7:0] Sub_out;

    always @(posedge Clk) begin
        if (A_en)
            A <= A_MUX_out;
        if (B_en)
            B <= B_MUX_out;
    end

    assign A_MUX_out = A_MUX_sel[1] ? B : (A_MUX_sel[0] ? Sub_out : A_in);
    assign B_MUX_out = B_MUX_sel ? A : B_in;
    assign Sub_out = A - B;
    assign A_lt_B = (A < B);
    assign B_eq_0 = (B == 0);
    assign gcd_out = A;

endmodule

// Control Path
module controlpath (
    input ack, Rst, Clk, operands_val, A_lt_B, B_eq_0,
    output reg [1:0] A_MUX_sel,
    output reg B_MUX_sel,
    output gcd_valid,
    output reg A_en, B_en
);

    reg [1:0] state;
    reg [1:0] state_next;

    // State Encoding
    parameter idle = 2'b00;
    parameter busy = 2'b01;
    parameter done = 2'b10;

    // State Transition
    always @(posedge Clk or posedge Rst) begin
        if (Rst)
            state <= idle;
        else
            state <= state_next;
    end

    // Next State Logic + Output Logic
    always @(*) begin
        // Default assignments to avoid latches
        A_MUX_sel = 2'b00;
        B_MUX_sel = 1'b0;
        A_en = 1'b0;
        B_en = 1'b0;
        state_next = state;

        case (state)
            idle: begin
                A_MUX_sel = 2'b00;
                B_MUX_sel = 1'b0;
                A_en = 1'b1;
                B_en = 1'b1;
                if (operands_val)
                    state_next = busy;
            end

            busy: begin
                if (A_lt_B) begin
                    A_MUX_sel = 2'b10;
                    B_MUX_sel = 1'b1;
                    A_en = 1'b1;
                    B_en = 1'b1;
                end else begin
                    A_MUX_sel = 2'b01;
                    B_MUX_sel = 1'b0;
                    A_en = 1'b1;
                    B_en = 1'b0;
                end

                if (B_eq_0)
                    state_next = done;
            end

            done: begin
                A_en = 0;
                B_en = 0;
                if (ack)
                    state_next = idle;
            end
        endcase
    end

    assign gcd_valid = (state == done);

endmodule
