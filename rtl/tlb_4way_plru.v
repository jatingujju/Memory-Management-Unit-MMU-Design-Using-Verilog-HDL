module tlb_4way_plru
#(
    parameter VPN_WIDTH  = 20,
    parameter PFN_WIDTH  = 20,
    parameter ASID_WIDTH = 8,
    parameter NUM_SETS   = 4
)
(
    input wire clk,
    input wire rst_n,

    // Lookup Port
    input wire lookup_valid,
    input wire [VPN_WIDTH-1:0] lookup_vpn,
    input wire [ASID_WIDTH-1:0] lookup_asid,

    output reg hit,
    output reg [PFN_WIDTH-1:0] hit_pfn,

    // Refill Port
    input wire refill_valid,
    input wire [VPN_WIDTH-1:0] refill_vpn,
    input wire [ASID_WIDTH-1:0] refill_asid,
    input wire [PFN_WIDTH-1:0] refill_pfn
);

integer i,j;

reg valid_mem [0:NUM_SETS-1][0:3];

reg [VPN_WIDTH-1:0] vpn_mem [0:NUM_SETS-1][0:3];
reg [PFN_WIDTH-1:0] pfn_mem [0:NUM_SETS-1][0:3];
reg [ASID_WIDTH-1:0] asid_mem [0:NUM_SETS-1][0:3];

reg [1:0] replace_ptr [0:NUM_SETS-1];

wire [1:0] lookup_set;
wire [1:0] refill_set;

assign lookup_set = lookup_vpn[1:0];
assign refill_set = refill_vpn[1:0];

reg [3:0] way_hit;
reg [1:0] hit_way;

always @(*)
begin

    way_hit[0] =
        valid_mem[lookup_set][0] &&
        (vpn_mem[lookup_set][0] == lookup_vpn) &&
        (asid_mem[lookup_set][0] == lookup_asid);

    way_hit[1] =
        valid_mem[lookup_set][1] &&
        (vpn_mem[lookup_set][1] == lookup_vpn) &&
        (asid_mem[lookup_set][1] == lookup_asid);

    way_hit[2] =
        valid_mem[lookup_set][2] &&
        (vpn_mem[lookup_set][2] == lookup_vpn) &&
        (asid_mem[lookup_set][2] == lookup_asid);

    way_hit[3] =
        valid_mem[lookup_set][3] &&
        (vpn_mem[lookup_set][3] == lookup_vpn) &&
        (asid_mem[lookup_set][3] == lookup_asid);

end

always @(*)
begin

    hit = |way_hit;

    hit_way = 2'd0;

    if(way_hit[0])
        hit_way = 2'd0;
    else if(way_hit[1])
        hit_way = 2'd1;
    else if(way_hit[2])
        hit_way = 2'd2;
    else if(way_hit[3])
        hit_way = 2'd3;

    hit_pfn = 0;

    if(hit)
        hit_pfn = pfn_mem[lookup_set][hit_way];

end

always @(posedge clk or negedge rst_n)
begin

    if(!rst_n)
    begin

        for(i=0;i<NUM_SETS;i=i+1)
        begin

            replace_ptr[i] <= 0;

            for(j=0;j<4;j=j+1)
            begin
                valid_mem[i][j] <= 0;
            end

        end

    end
    else
    begin

        if(refill_valid)
        begin

            valid_mem[refill_set][replace_ptr[refill_set]]
                <= 1'b1;

            vpn_mem[refill_set][replace_ptr[refill_set]]
                <= refill_vpn;

            asid_mem[refill_set][replace_ptr[refill_set]]
                <= refill_asid;

            pfn_mem[refill_set][replace_ptr[refill_set]]
                <= refill_pfn;

            replace_ptr[refill_set]
                <= replace_ptr[refill_set] + 1'b1;

        end

    end

end

endmodule