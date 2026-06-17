module ptw_fsm
(
    input wire clk,
    input wire rst_n,

    //------------------------------------------------
    // PTW Request
    //------------------------------------------------

    input wire start_walk,

    input wire [31:0] satp_base,
    input wire [19:0] vpn,

    //------------------------------------------------
    // Memory Interface
    //------------------------------------------------

    output reg        mem_req,
    output reg [31:0] mem_addr,

    input wire        mem_ready,
    input wire [31:0] mem_rdata,

    //------------------------------------------------
    // Refill Outputs
    //------------------------------------------------

    output reg        refill_valid,

    output reg [19:0] refill_vpn,
    output reg [19:0] refill_pfn,

    output reg        refill_v,
    output reg        refill_r,
    output reg        refill_w,
    output reg        refill_x,
    output reg        refill_u,

    //------------------------------------------------
    // Status
    //------------------------------------------------

    output reg done,
    output reg page_fault
);

localparam IDLE      = 2'b00;
localparam REQUEST   = 2'b01;
localparam CHECK_PTE = 2'b10;
localparam COMPLETE  = 2'b11;

reg [1:0] state;

always @(posedge clk or negedge rst_n)
begin

    if(!rst_n)
    begin

        state <= IDLE;

        mem_req <= 0;
        mem_addr <= 0;

        refill_valid <= 0;

        refill_vpn <= 0;
        refill_pfn <= 0;

        refill_v <= 0;
        refill_r <= 0;
        refill_w <= 0;
        refill_x <= 0;
        refill_u <= 0;

        done <= 0;
        page_fault <= 0;

    end
    else
    begin

        refill_valid <= 0;
        done <= 0;

        case(state)

        //--------------------------------------------
        // IDLE
        //--------------------------------------------

        IDLE:
        begin

            page_fault <= 0;

            if(start_walk)
            begin

                mem_addr <= satp_base + {vpn,2'b00};

                mem_req <= 1'b1;

                state <= REQUEST;

            end

        end

        //--------------------------------------------
        // WAIT FOR MEMORY
        //--------------------------------------------

        REQUEST:
        begin

            if(mem_ready)
            begin

                mem_req <= 0;

                state <= CHECK_PTE;

            end

        end

        //--------------------------------------------
        // DECODE PTE
        //--------------------------------------------

        CHECK_PTE:
        begin

            if(mem_rdata[5] == 1'b0)
            begin

                page_fault <= 1'b1;

                state <= COMPLETE;

            end
            else
            begin

                refill_vpn <= vpn;

                refill_pfn <= mem_rdata[31:12];

                refill_u <= mem_rdata[9];
                refill_x <= mem_rdata[8];
                refill_w <= mem_rdata[7];
                refill_r <= mem_rdata[6];
                refill_v <= mem_rdata[5];

                refill_valid <= 1'b1;

                state <= COMPLETE;

            end

        end

        //--------------------------------------------
        // COMPLETE
        //--------------------------------------------

        COMPLETE:
        begin

            done <= 1'b1;

            state <= IDLE;

        end

        endcase

    end

end

endmodule