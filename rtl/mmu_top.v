module mmu_top
(
    input wire clk,
    input wire rst_n,

    //------------------------------------------------
    // CPU Interface
    //------------------------------------------------

    input wire req_valid,

    input wire [31:0] virtual_addr,

    input wire [1:0] access_type,
    input wire user_mode,

    //------------------------------------------------
    // Memory Interface
    //------------------------------------------------

    output wire mem_req,
    output wire [31:0] mem_addr,

    input wire mem_ready,
    input wire [31:0] mem_rdata,

    //------------------------------------------------
    // Outputs
    //------------------------------------------------

    output reg resp_valid,

    output reg [31:0] physical_addr,

    output wire page_fault,
    output wire read_fault,
    output wire write_fault,
    output wire execute_fault,
    output wire user_fault
);

localparam MMU_IDLE     = 2'b00;
localparam MMU_LOOKUP   = 2'b01;
localparam MMU_WAIT_PTW = 2'b10;

reg [1:0] state;

wire [19:0] vpn;
wire [11:0] page_offset;

assign vpn         = virtual_addr[31:12];
assign page_offset = virtual_addr[11:0];

wire [31:0] satp_base;
wire [7:0]  asid;
wire        mmu_enable;

csr_registers u_csr
(
    .clk(clk),
    .rst_n(rst_n),

    .csr_we(1'b0),
    .csr_addr(2'b00),
    .csr_wdata(32'd0),

    .satp_base(satp_base),
    .asid(asid),
    .mmu_enable(mmu_enable)
);

wire tlb_hit;
wire [19:0] tlb_pfn;

wire refill_valid;
wire [19:0] refill_vpn;
wire [19:0] refill_pfn;

wire refill_v;
wire refill_r;
wire refill_w;
wire refill_x;
wire refill_u;

tlb_4way_plru u_tlb
(
    .clk(clk),
    .rst_n(rst_n),

    .lookup_valid(req_valid),
    .lookup_vpn(vpn),
    .lookup_asid(asid),

    .hit(tlb_hit),
    .hit_pfn(tlb_pfn),

    .refill_valid(refill_valid),
    .refill_vpn(refill_vpn),
    .refill_asid(asid),
    .refill_pfn(refill_pfn)
);

wire ptw_done;

ptw_fsm u_ptw
(
    .clk(clk),
    .rst_n(rst_n),

    .start_walk(state == MMU_WAIT_PTW),

    .satp_base(satp_base),
    .vpn(vpn),

    .mem_req(mem_req),
    .mem_addr(mem_addr),

    .mem_ready(mem_ready),
    .mem_rdata(mem_rdata),

    .refill_valid(refill_valid),

    .refill_vpn(refill_vpn),
    .refill_pfn(refill_pfn),

    .refill_v(refill_v),
    .refill_r(refill_r),
    .refill_w(refill_w),
    .refill_x(refill_x),
    .refill_u(refill_u),

    .done(ptw_done),
    .page_fault(page_fault)
);

wire access_granted;

permission_checker u_perm
(
    .access_type(access_type),
    .user_mode(user_mode),

    .pte_valid(tlb_hit),

    .pte_r(1'b1),
    .pte_w(1'b1),
    .pte_x(1'b1),
    .pte_u(1'b1),

    .access_granted(access_granted),

    .page_fault(),
    .read_fault(read_fault),
    .write_fault(write_fault),
    .execute_fault(execute_fault),
    .user_fault(user_fault)
);

wire [31:0] translated_addr;

address_translator u_addr
(
    .pfn(tlb_pfn),
    .page_offset(page_offset),
    .physical_addr(translated_addr)
);

always @(posedge clk or negedge rst_n)
begin

    if(!rst_n)
    begin

        state <= MMU_IDLE;

        resp_valid <= 0;
        physical_addr <= 0;

    end
    else
    begin

        resp_valid <= 0;

        case(state)

        //------------------------------------
        // IDLE
        //------------------------------------

        MMU_IDLE:
        begin

            if(req_valid)
                state <= MMU_LOOKUP;

        end

        //------------------------------------
        // LOOKUP
        //------------------------------------

        MMU_LOOKUP:
        begin

            //--------------------------------
            // Bypass Mode
            //--------------------------------

            if(!mmu_enable)
            begin

                physical_addr <= virtual_addr;

                resp_valid <= 1;

                state <= MMU_IDLE;

            end

            //--------------------------------
            // TLB Hit
            //--------------------------------

            else if(tlb_hit && access_granted)
            begin

                physical_addr <= translated_addr;

                resp_valid <= 1;

                state <= MMU_IDLE;

            end

            //--------------------------------
            // TLB Miss
            //--------------------------------

            else
            begin

                state <= MMU_WAIT_PTW;

            end

        end

        //------------------------------------
        // WAIT FOR PTW
        //------------------------------------

        MMU_WAIT_PTW:
        begin

            if(ptw_done)
            begin

                state <= MMU_LOOKUP;

            end

        end

        endcase

    end

end

endmodule