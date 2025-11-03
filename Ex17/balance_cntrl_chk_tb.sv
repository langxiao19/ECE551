// balance_cntrl_chk_tb.sv - Testbench for balance_cntrl
// Tests balance_cntrl using stimulus and expected response from hex files

module balance_cntrl_chk_tb();

  //////////////////////////////////////////
  // Declare stimulus and response vectors //
  //////////////////////////////////////////
  reg [48:0] stim;        // 49-bit stimulus vector
  reg [24:0] resp;        // 25-bit response vector
  
  // Memory arrays to hold stimulus and expected response
  reg [48:0] stim_mem[0:1499];   // 1500 stimulus vectors
  reg [24:0] resp_mem[0:1499];   // 1500 response vectors
  
  //////////////////////////////////
  // Declare testbench signals   //
  //////////////////////////////////
  reg clk;
  integer i;              // Loop counter
  integer errors;         // Error counter
  
  /////////////////////////////////////////////////
  // Assign stimulus bits to DUT input signals  //
  /////////////////////////////////////////////////
  wire rst_n      = stim[48];
  wire vld        = stim[47];
  wire signed [15:0] ptch    = stim[46:31];
  wire signed [15:0] ptch_rt = stim[30:15];
  wire pwr_up     = stim[14];
  wire rider_off  = stim[13];
  wire [11:0] steer_pot = stim[12:1];
  wire en_steer   = stim[0];
  
  ///////////////////////////////////
  // DUT output signals           //
  ///////////////////////////////////
  wire signed [11:0] lft_spd;
  wire signed [11:0] rght_spd;
  wire too_fast;
  
  ///////////////////////////////////////////
  // Expected response from response file //
  ///////////////////////////////////////////
  wire signed [11:0] exp_lft_spd  = resp[24:13];
  wire signed [11:0] exp_rght_spd = resp[12:1];
  wire exp_too_fast = resp[0];
  
  //////////////////////
  // Instantiate DUT //
  //////////////////////
  balance_cntrl #(.fast_sim(1)) iDUT (
    .clk(clk),
    .rst_n(rst_n),
    .vld(vld),
    .ptch(ptch),
    .ptch_rt(ptch_rt),
    .pwr_up(pwr_up),
    .rider_off(rider_off),
    .steer_pot(steer_pot),
    .en_steer(en_steer),
    .lft_spd(lft_spd),
    .rght_spd(rght_spd),
    .too_fast(too_fast)
  );
  
  /////////////////////
  // Clock generator //
  /////////////////////
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end
  
  ///////////////////////
  // Main test block  //
  ///////////////////////
  initial begin
    // Initialize error counter
    errors = 0;
    
    // Read stimulus and response files into memory
    $readmemh("balance_cntrl_stim.hex", stim_mem);
    $readmemh("balance_cntrl_resp.hex", resp_mem);
    
    // Initialize stimulus
    stim = 49'h0000000000000;
    
    // Wait a bit before forcing
    #1;
    
    // Force ss_tmr to 0xFF as specified  
    force iDUT.ss_tmr = 8'hFF;
    
    // Wait a bit for initialization
    @(posedge clk);
    @(negedge clk);
    
    // Loop through all 1500 test vectors
    for (i = 0; i < 1500; i = i + 1) begin
      // Apply stimulus vector
      stim = stim_mem[i];
      
      // Wait for clock edge and propagation delay
      @(posedge clk);
      #1;  // Wait 1 time unit after rising edge
      
      // Get expected response
      resp = resp_mem[i];
      
      // Check outputs against expected response
      if (lft_spd !== exp_lft_spd) begin
        $display("ERROR at vector %0d: lft_spd mismatch! Expected: %h, Got: %h", 
                 i, exp_lft_spd, lft_spd);
        errors = errors + 1;
      end
      
      if (rght_spd !== exp_rght_spd) begin
        $display("ERROR at vector %0d: rght_spd mismatch! Expected: %h, Got: %h", 
                 i, exp_rght_spd, rght_spd);
        errors = errors + 1;
      end
      
      if (too_fast !== exp_too_fast) begin
        $display("ERROR at vector %0d: too_fast mismatch! Expected: %b, Got: %b", 
                 i, exp_too_fast, too_fast);
        errors = errors + 1;
      end
      
      // Print progress every 100 vectors
      if ((i % 100) == 0) begin
        $display("Progress: %0d/1500 vectors tested...", i);
      end
    end
    
    // Print final results
    $display("\n========================================");
    if (errors == 0) begin
      $display("SUCCESS! All 1500 vectors passed!");
      $display("========================================\n");
    end else begin
      $display("FAILED! %0d errors found in 1500 vectors", errors);
      $display("========================================\n");
    end
    
    $stop();
  end

endmodule
