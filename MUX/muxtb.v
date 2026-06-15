`timescale 1ns / 1ps

module muxtb;

    reg a;
    reg b;
    reg sel;
    wire out;
    
    integer s_loop, a_loop, b_loop;
    
    Mux uut(
        .a(a),
        .b(b),
        .sel(sel),
        .out(out)
    );
    
    initial begin
        $display("Time\t sel a b | out");
        
        for (s_loop = 0; s_loop < 2; s_loop = s_loop + 1)begin
         for (a_loop = 0; a_loop < 2; a_loop = a_loop + 1)begin
          for (b_loop = 0; b_loop < 2; b_loop = b_loop + 1)begin
          
          sel = s_loop;
          a   = a_loop;
          b   = b_loop;
          
          #10;
          
          $display("%0dtns\t %b %b %b | %b", $time, sel, a, b, out);
          end
         end
        end
    $finish;
    end
endmodule;
