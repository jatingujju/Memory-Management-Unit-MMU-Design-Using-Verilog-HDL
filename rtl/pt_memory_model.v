module pt_memory_model
(
    input  wire        clk,
    input  wire        rst_n,

    //-----------------------------------------
    // PTW Interface
    //-----------------------------------------

    input  wire        mem_req,
    input  wire [31:0] mem_addr,

    output reg         mem_ready,
    output reg [31:0]  mem_rdata
);

localparam DEPTH = 64;

reg [31:0] mem [0:DEPTH-1];

integer i;

wire [5:0] word_index;

/*
    PTW generates:

    pte_addr = satp_base + vpn*4

    Since this is a small simulation model,
    we only use lower address bits.
*/

assign word_index = mem_addr[7:2];

always @(posedge clk or negedge rst_n)
begin

    if(!rst_n)
    begin

        mem_ready <= 1'b0;
        mem_rdata <= 32'd0;

        //-------------------------------------
        // Clear memory
        //-------------------------------------

        for(i=0;i<DEPTH;i=i+1)
        begin
            mem[i] <= 32'd0;
        end

        //-------------------------------------
        // Sample Page Table Entries
        //-------------------------------------

        /*
            VPN 0
            PFN = 0x10000
            V R W X U = 1
        */

        mem[0] <=
        {
            20'h10000,
            2'b00,
            1'b1, // U
            1'b1, // X
            1'b1, // W
            1'b1, // R
            1'b1, // V
            5'b00000
        };

        /*
            VPN 1
            Read Only
        */

        mem[1] <=
        {
            20'h10001,
            2'b00,
            1'b1,
            1'b0,
            1'b0,
            1'b1,
            1'b1,
            5'b00000
        };

        /*
            VPN 2
            Invalid Page
        */

        mem[2] <=
        {
            20'h10002,
            2'b00,
            1'b1,
            1'b1,
            1'b1,
            1'b1,
            1'b0,
            5'b00000
        };

        /*
            VPN 3
            Supervisor Only
        */

        mem[3] <=
        {
            20'h10003,
            2'b00,
            1'b0,
            1'b1,
            1'b1,
            1'b1,
            1'b1,
            5'b00000
        };

    end
    else
    begin

        mem_ready <= 1'b0;

        //-------------------------------------
        // Single-cycle BRAM Read
        //-------------------------------------

        if(mem_req)
        begin

            mem_rdata <= mem[word_index];

            mem_ready <= 1'b1;

        end

    end

end

endmodule