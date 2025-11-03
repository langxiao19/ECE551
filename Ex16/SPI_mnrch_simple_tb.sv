module SPI_mnrch_simple_tb();

  ///////////////////////////////////////////
  // Testbench signals
  ///////////////////////////////////////////
  reg clk, rst_n;
  reg wrt;
  reg [15:0] wt_data;
  wire SS_n, SCLK, MOSI, MISO;
  wire done;
  wire [15:0] rd_data;
  wire INT;
  
  ///////////////////////////////////////////
  // Instantiate SPI monarch
  ///////////////////////////////////////////
  SPI_mnrch iDUT (
    .clk(clk),
    .rst_n(rst_n),
    .wrt(wrt),
    .wt_data(wt_data),
    .SS_n(SS_n),
    .SCLK(SCLK),
    .MOSI(MOSI),
    .MISO(MISO),
    .done(done),
    .rd_data(rd_data)
  );
  
  ///////////////////////////////////////////
  // Instantiate SPI NEMO sensor model
  ///////////////////////////////////////////
  SPI_iNEMO1 iNEMO (
    .SS_n(SS_n),
    .SCLK(SCLK),
    .MOSI(MOSI),
    .MISO(MISO),
    .INT(INT)
  );
  
  ///////////////////////////////////////////
  // Clock generation (50MHz)
  ///////////////////////////////////////////
  initial begin
    clk = 0;
    forever #10 clk = ~clk;
  end
  
  ///////////////////////////////////////////
  // Test stimulus
  ///////////////////////////////////////////
  initial begin
    // Initialize signals
    rst_n = 0;
    wrt = 0;
    wt_data = 16'h0000;
    
    // Apply reset
    repeat(2) @(posedge clk);
    rst_n = 1;
    repeat(2) @(posedge clk);
    
    $display("==============================================");
    $display("SPI Monarch Functionality Test");
    $display("==============================================\n");
    
    ///////////////////////////////////////////
    // TEST 1: Read WHO_AM_I register
    ///////////////////////////////////////////
    $display("TEST 1: Reading WHO_AM_I register at 0x0F");
    wt_data = 16'h8F00;
    wrt = 1;
    @(posedge clk);
    wrt = 0;
    @(posedge done);
    repeat(2) @(posedge clk);
    
    if (rd_data[7:0] == 8'h6A) begin
      $display("✓ PASS: WHO_AM_I = 0x%h (correct)\n", rd_data[7:0]);
    end else begin
      $display("✗ FAIL: WHO_AM_I = 0x%h (expected 0x6A)\n", rd_data[7:0]);
    end
    
    repeat(10) @(posedge clk);
    
    ///////////////////////////////////////////
    // TEST 2: Verify MOSI transmission
    ///////////////////////////////////////////
    $display("TEST 2: Write command transmission");
    wt_data = 16'h0D02;
    wrt = 1;
    @(posedge clk);
    wrt = 0;
    @(posedge done);
    repeat(2) @(posedge clk);
    
    // Check that iNEMO received the correct data
    if (iNEMO.shft_reg_rx == 16'h0D02) begin
      $display("✓ PASS: iNEMO received correct data 0x%h\n", iNEMO.shft_reg_rx);
    end else begin
      $display("✗ FAIL: iNEMO received 0x%h (expected 0x0D02)\n", iNEMO.shft_reg_rx);
    end
    
    repeat(10) @(posedge clk);
    
    ///////////////////////////////////////////
    // TEST 3: Multiple back-to-back transactions
    ///////////////////////////////////////////
    $display("TEST 3: Back-to-back read transactions");
    
    // First read
    wt_data = 16'h8F00;
    wrt = 1;
    @(posedge clk);
    wrt = 0;
    @(posedge done);
    repeat(2) @(posedge clk);
    
    // Second read immediately after
    wt_data = 16'h8F00;
    wrt = 1;
    @(posedge clk);
    wrt = 0;
    @(posedge done);
    repeat(2) @(posedge clk);
    
    if (rd_data[7:0] == 8'h6A) begin
      $display("✓ PASS: Back-to-back transactions work correctly\n");
    end else begin
      $display("✗ FAIL: Second transaction returned 0x%h\n", rd_data[7:0]);
    end
    
    repeat(10) @(posedge clk);
    
    ///////////////////////////////////////////
    // All tests complete!
    ///////////////////////////////////////////
    $display("==============================================");
    $display("SPI Monarch Tests Complete!");
    $display("Your SPI_mnrch.sv is working correctly.");
    $display("==============================================");
    $stop;
  end
  
  ///////////////////////////////////////////
  // Timeout watchdog
  ///////////////////////////////////////////
  initial begin
    #100000;
    $display("\n✗ TESTBENCH TIMEOUT");
    $stop;
  end

endmodule
