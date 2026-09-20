module adder_32bit (
    input [32:1] A,
    input [32:1] B,
    output [32:1] S,
    output C32
);
    function automatic [33:1] add32;
        input [32:1] a;
        input [32:1] b;
        begin
            add32 = a + b;
        end
    endfunction

    assign {C32, S} = add32(A, B);
endmodule
