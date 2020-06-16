module missionary_cannibal_tb();

  reg       clock;
  reg       reset;
  wire[1:0] missionary_next;
  wire[1:0] cannibal_next;
  wire      finish;

  //..log info
  initial begin
    $dumpfile("missionary_cannibal.vcd");
    $dumpvars();
    $monitor("[Cycle: %3d] M-Curr: %2d | C-Curr: %2d | Dir: %2d | M-Nxt: %2d | C-Nxt: %2d | Finish: %2d", $time, dut.missionary_curr, dut.cannibal_curr, dut.direction, missionary_next, cannibal_next, finish);
  end

  initial begin
    clock = 0;
    reset = 1;
  end

  //..clock sim
  always
    #1 clock = ~clock;

  //..reset sim
  always
    #2 reset = 0;

  //..end sim
  always begin
    #1;
    if(finish)
      $finish;
  end

  //..dut top module
  missionary_cannibal
    dut (
      .clock            (clock),
      .reset            (reset),
      .missionary_next  (missionary_next),
      .cannibal_next    (cannibal_next),
      .finish           (finish)
    );

endmodule
