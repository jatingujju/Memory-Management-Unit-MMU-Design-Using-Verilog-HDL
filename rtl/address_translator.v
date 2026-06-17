module address_translator
(
    input  wire [19:0] pfn,
    input  wire [11:0] page_offset,

    output wire [31:0] physical_addr
);

assign physical_addr =
{
    pfn,
    page_offset
};

endmodule