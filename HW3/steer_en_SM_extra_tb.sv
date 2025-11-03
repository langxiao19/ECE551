module steer_en_SM_extra_tb();

  reg clk,rst_n;
  reg tmr_full;
  reg sum_gt_min;
  reg sum_lt_min;
  reg diff_gt_1_4;
  reg diff_gt_15_16;
  
  wire clr_tmr, en_steer, rider_off;
  
  steer_en_SM iDUT(.clk(clk),.rst_n(rst_n),.tmr_full(tmr_full),.sum_gt_min(sum_gt_min),
                   .sum_lt_min(sum_lt_min),.diff_gt_1_4(diff_gt_1_4),
				   .diff_gt_15_16(diff_gt_15_16),.clr_tmr(clr_tmr),.en_steer(en_steer),
				   .rider_off(rider_off));
  
  initial begin
    clk=0;
	rst_n = 0;
	tmr_full = 0;
	sum_gt_min = 0;
	sum_lt_min = 1;
	diff_gt_1_4 = 0;
	diff_gt_15_16 = 0;
	
	@(posedge clk);
	@(negedge clk);
	rst_n = 1;
	
	$display("=== Testing transition from STEER_EN to INITIAL on sum_lt_min ===");
	
	// Get to steering enabled state
	sum_gt_min = 1;
	sum_lt_min = 0;
	@(negedge clk);  // Move to WAIT_BALANCE
	
	// Wait for timer to expire and enter STEER_EN
	tmr_full = 1;
	@(negedge clk);  // Move to STEER_EN
	tmr_full = 0;
	
	if (!en_steer) begin
	  $display("ERROR: Should be in steering enabled state");
	  $stop();
	end
	if (rider_off) begin
	  $display("ERROR: rider_off should not be asserted in STEER_EN");
	  $stop();
	end
	$display("GOOD: In steering enabled state");
	
	// Now test sudden rider fall off (sum_lt_min)
	sum_gt_min = 0;
	sum_lt_min = 1;
	@(negedge clk);
	
	if (en_steer) begin
	  $display("ERROR: en_steer should be deasserted after sum_lt_min");
	  $stop();
	end
	if (!rider_off) begin
	  $display("ERROR: rider_off should be asserted in INITIAL state");
	  $stop();
	end
	if (iDUT.state != 2'b00) begin
	  $display("ERROR: Should be in INITIAL state (00) after sum_lt_min");
	  $stop();
	end
	
	$display("SUCCESS: Correctly transitioned from STEER_EN to INITIAL on sum_lt_min");
	$display("All tests passed!");
	$stop();
  end
  
  always
    #10 clk = ~clk;
	
endmodule
