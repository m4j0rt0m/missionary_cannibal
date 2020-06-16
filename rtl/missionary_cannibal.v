module missionary_cannibal(/*AUTOARG*/
   // Outputs
   missionary_next, cannibal_next, finish,
   // Inputs
   clock, reset
   );

  /* ports */
  input clock,reset;
  output[1:0] missionary_next;
  output[1:0] cannibal_next;
  output finish;

  reg       direction;
  reg [1:0] missionary_curr;
  reg [1:0] cannibal_curr;

  assign finish = &(~missionary_next) & &(~cannibal_next);

  /* toggle direction */
  always @ (posedge clock, posedge reset) begin
    if(reset)
      direction <= 1'b0;
    else
      direction <= ~direction;
  end

  always @ (posedge clock, posedge reset) begin
    if(reset) begin
      missionary_curr <= 2'd0;
      cannibal_curr   <= 2'd0;
    end
    else begin
      missionary_curr <= missionary_next;
      cannibal_curr   <= cannibal_next;
    end
  end

  ms m1 (missionary_curr, cannibal_curr, direction, missionary_next, cannibal_next);

endmodule // missionary_cannibal
