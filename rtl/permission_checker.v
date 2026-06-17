module permission_checker
(
    input wire [1:0] access_type,
    input wire user_mode,

    input wire pte_valid,
    input wire pte_r,
    input wire pte_w,
    input wire pte_x,
    input wire pte_u,

    output reg access_granted,

    output reg page_fault,
    output reg read_fault,
    output reg write_fault,
    output reg execute_fault,
    output reg user_fault
);

always @(*)
begin

    access_granted = 0;

    page_fault = 0;
    read_fault = 0;
    write_fault = 0;
    execute_fault = 0;
    user_fault = 0;

    if(!pte_valid)
    begin
        page_fault = 1;
    end
    else if(user_mode && !pte_u)
    begin
        user_fault = 1;
    end
    else
    begin

        case(access_type)

            2'b00:
            begin
                if(pte_r)
                    access_granted = 1;
                else
                    read_fault = 1;
            end

            2'b01:
            begin
                if(pte_w)
                    access_granted = 1;
                else
                    write_fault = 1;
            end

            2'b10:
            begin
                if(pte_x)
                    access_granted = 1;
                else
                    execute_fault = 1;
            end

        endcase
    end
end

endmodule