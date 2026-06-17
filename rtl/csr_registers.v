module csr_registers
(
    input  wire        clk,
    input  wire        rst_n,

    input  wire        csr_we,
    input  wire [1:0]  csr_addr,
    input  wire [31:0] csr_wdata,

    output reg [31:0] satp_base,
    output reg [7:0]  asid,
    output reg        mmu_enable
);

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        satp_base <= 32'h1000_0000;
        asid      <= 8'd0;
        mmu_enable<= 1'b1;
    end
    else if(csr_we)
    begin
        case(csr_addr)

            2'b00:
                satp_base <= csr_wdata;

            2'b01:
                asid <= csr_wdata[7:0];

            2'b10:
                mmu_enable <= csr_wdata[0];

        endcase
    end
end

endmodule