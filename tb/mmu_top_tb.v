`timescale 1ns/1ps

module mmu_top_tb;

reg clk;
reg rst_n;

// CPU Request Interface
reg         req_valid;
reg [31:0]  virtual_addr;
reg [1:0]   access_type;
reg         user_mode;

// DUT Outputs
wire        resp_valid;
wire [31:0] physical_addr;

wire page_fault;
wire read_fault;
wire write_fault;
wire execute_fault;
wire user_fault;

// Memory Interface
wire        mem_req;
wire [31:0] mem_addr;
wire        mem_ready;
wire [31:0] mem_rdata;

/////////////////////////////////////////////////
// DUT
/////////////////////////////////////////////////

mmu_top DUT
(
    .clk(clk),
    .rst_n(rst_n),

    .req_valid(req_valid),
    .virtual_addr(virtual_addr),

    .access_type(access_type),
    .user_mode(user_mode),

    .mem_req(mem_req),
    .mem_addr(mem_addr),

    .mem_ready(mem_ready),
    .mem_rdata(mem_rdata),

    .resp_valid(resp_valid),
    .physical_addr(physical_addr),

    .page_fault(page_fault),
    .read_fault(read_fault),
    .write_fault(write_fault),
    .execute_fault(execute_fault),
    .user_fault(user_fault)
);

/////////////////////////////////////////////////
// Page Table BRAM Model
/////////////////////////////////////////////////

pt_memory_model MEM
(
    .clk(clk),
    .rst_n(rst_n),

    .mem_req(mem_req),
    .mem_addr(mem_addr),

    .mem_ready(mem_ready),
    .mem_rdata(mem_rdata)
);

/////////////////////////////////////////////////
// Clock
/////////////////////////////////////////////////

always #5 clk = ~clk;

/////////////////////////////////////////////////
// Helper Task
/////////////////////////////////////////////////

task issue_request;

input [31:0] addr;
input [1:0] access;
input mode;

begin

    @(posedge clk);

    virtual_addr <= addr;
    access_type  <= access;
    user_mode    <= mode;

    req_valid <= 1'b1;

    @(posedge clk);

    req_valid <= 1'b0;

    repeat(10) @(posedge clk);

end

endtask

/////////////////////////////////////////////////
// Test Sequence
/////////////////////////////////////////////////

initial
begin

    $dumpfile("mmu.vcd");
    $dumpvars(0, mmu_top_tb);

    clk = 0;
    rst_n = 0;

    req_valid = 0;
    virtual_addr = 0;
    access_type = 0;
    user_mode = 0;

    //------------------------------------------------
    // Reset
    //------------------------------------------------

    #20;
    rst_n = 1;

    //------------------------------------------------
    // TEST 1
    // VPN 0
    // TLB MISS -> PTW REFILL
    //------------------------------------------------

    $display("");
    $display("TEST1 : TLB MISS / REFILL");

    issue_request(
        32'h0000_0123,
        2'b00,
        1'b1
    );

    //------------------------------------------------
    // TEST 2
    // SAME VPN
    // EXPECT TLB HIT
    //------------------------------------------------

    $display("");
    $display("TEST2 : TLB HIT");

    issue_request(
        32'h0000_0155,
        2'b00,
        1'b1
    );

    //------------------------------------------------
    // TEST 3
    // VPN1
    // READ ONLY PAGE
    // WRITE ACCESS
    //------------------------------------------------

    $display("");
    $display("TEST3 : WRITE FAULT");

    issue_request(
        32'h0000_1000,
        2'b01,
        1'b1
    );

    //------------------------------------------------
    // TEST 4
    // VPN2
    // INVALID PAGE
    //------------------------------------------------

    $display("");
    $display("TEST4 : PAGE FAULT");

    issue_request(
        32'h0000_2000,
        2'b00,
        1'b1
    );

    //------------------------------------------------
    // TEST 5
    // VPN3
    // SUPERVISOR PAGE
    // USER ACCESS
    //------------------------------------------------

    $display("");
    $display("TEST5 : USER FAULT");

    issue_request(
        32'h0000_3000,
        2'b00,
        1'b1
    );

    //------------------------------------------------
    // TEST 6
    // SUPERVISOR ACCESS
    //------------------------------------------------

    $display("");
    $display("TEST6 : SUPERVISOR ACCESS");

    issue_request(
        32'h0000_3000,
        2'b00,
        1'b0
    );

    //------------------------------------------------
    // TEST 7
    // EXECUTE ACCESS
    //------------------------------------------------

    $display("");
    $display("TEST7 : EXECUTE ACCESS");

    issue_request(
        32'h0000_0123,
        2'b10,
        1'b1
    );

    //------------------------------------------------
    // TEST 8
    // ASID Isolation Example
    //------------------------------------------------

    $display("");
    $display("TEST8 : ASID ISOLATION");

    DUT.u_csr.asid = 8'h01;

    issue_request(
        32'h0000_0123,
        2'b00,
        1'b1
    );

    DUT.u_csr.asid = 8'h02;

    issue_request(
        32'h0000_0123,
        2'b00,
        1'b1
    );

    //------------------------------------------------
    // TEST 9
    // MMU BYPASS MODE
    //------------------------------------------------

    $display("");
    $display("TEST9 : MMU BYPASS");

    DUT.u_csr.mmu_enable = 1'b0;

    issue_request(
        32'hDEAD_BEEF,
        2'b00,
        1'b1
    );

    //------------------------------------------------

    #100;

    $display("");
    $display("ALL TESTS COMPLETED");

    $finish;

end

/////////////////////////////////////////////////
// Monitor
/////////////////////////////////////////////////

always @(posedge clk)
begin

    if(resp_valid)
    begin

        $display(
            "TIME=%0t PA=%h PF=%b RF=%b WF=%b XF=%b UF=%b",
            $time,
            physical_addr,
            page_fault,
            read_fault,
            write_fault,
            execute_fault,
            user_fault
        );

    end

end

endmodule