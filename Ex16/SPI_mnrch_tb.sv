module SPI_mnrch_tb();

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
    forever #10 clk = ~clk;  // 50MHz clock (20ns period)
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
    $display("Starting SPI Monarch Testbench");
    $display("==============================================\n");
    
    ///////////////////////////////////////////
    // TEST 1: Read WHO_AM_I register (0x0F)
    // Expected response: 0x6A
    ///////////////////////////////////////////
    $display("TEST 1: Reading WHO_AM_I register at 0x0F");
    $display("Sending: 0x8Fxx (read from address 0x0F)");
    wt_data = 16'h8F00;
    wrt = 1;
    @(posedge clk);
    wrt = 0;
    
    // Wait for transaction to complete
    @(posedge done);
    repeat(2) @(posedge clk);
    
    // Check result
    if (rd_data[7:0] == 8'h6A) begin
      $display("✓ PASS: WHO_AM_I returned 0x%h (expected 0x6A)\n", rd_data[7:0]);
    end else begin
      $display("✗ FAIL: WHO_AM_I returned 0x%h (expected 0x6A)\n", rd_data[7:0]);
      $stop;
    end
    
    repeat(10) @(posedge clk);
    
    ///////////////////////////////////////////
    // TEST 2: Write to INT config register (0x0D)
    // Write 0x02 to enable INT on data ready
    ///////////////////////////////////////////
    $display("TEST 2: Writing to INT config register at 0x0D");
    $display("Sending: 0x0D02 (write 0x02 to address 0x0D)");
    wt_data = 16'h0D02;
    wrt = 1;
    @(posedge clk);
    wrt = 0;
    
    // Wait for transaction to complete
    @(posedge done);
    repeat(5) @(posedge clk);  // Wait a bit longer for SS_n to rise and register write
    
    // Check that NEMO_setup went high
    if (iNEMO.NEMO_setup) begin
      $display("✓ PASS: NEMO_setup asserted after INT config write\n");
    end else begin
      $display("✗ FAIL: NEMO_setup not asserted\n");
      $display("DEBUG: registers[0x0D] = 0x%h", iNEMO.registers[8'h0D]);
      $display("DEBUG: NEMO shft_reg_rx = 0x%h", iNEMO.shft_reg_rx);
      $display("DEBUG: write_reg = %b", iNEMO.write_reg);
      $stop;
    end
    
    repeat(10) @(posedge clk);
    
    ///////////////////////////////////////////
    // TEST 3: Wait for INT and read ptchL register (0xA2)
    // Expected: First byte from inert_data.hex
    ///////////////////////////////////////////
    $display("TEST 3: Waiting for INT assertion...");
    
    // Wait for INT to assert
    fork
      begin: timeout1
        repeat(100000) @(posedge clk);
        $display("✗ FAIL: Timeout waiting for INT\n");
        $stop;
      end
      begin
        @(posedge INT);
        disable timeout1;
      end
    join
    
    $display("INT asserted! Reading ptchL register at 0xA2");
    repeat(5) @(posedge clk);
    
    wt_data = 16'hA200;
    wrt = 1;
    @(posedge clk);
    wrt = 0;
    
    // Wait for transaction to complete
    @(posedge done);
    repeat(2) @(posedge clk);
    
    // According to inert_data.hex, first entry (@00) pitch=5663, so ptchL=0x63
    if (rd_data[7:0] == 8'h63) begin
      $display("✓ PASS: ptchL returned 0x%h (expected 0x63)", rd_data[7:0]);
    end else begin
      $display("✗ FAIL: ptchL returned 0x%h (expected 0x63)", rd_data[7:0]);
      $stop;
    end
    
    // Check that INT was cleared
    if (!INT) begin
      $display("✓ PASS: INT cleared after ptchL read\n");
    end else begin
      $display("✗ FAIL: INT not cleared after ptchL read\n");
      $stop;
    end
    
    repeat(10) @(posedge clk);
    
    ///////////////////////////////////////////
    // TEST 4: Read ptchH register (0xA3)
    ///////////////////////////////////////////
    $display("TEST 4: Reading ptchH register at 0xA3");
    wt_data = 16'hA300;
    wrt = 1;
    @(posedge clk);
    wrt = 0;
    
    // Wait for transaction to complete
    @(posedge done);
    repeat(2) @(posedge clk);
    
    // According to inert_data.hex, first entry (@00) pitch=5663, so ptchH=0x56
    if (rd_data[7:0] == 8'h56) begin
      $display("✓ PASS: ptchH returned 0x%h (expected 0x56)\n", rd_data[7:0]);
    end else begin
      $display("✗ FAIL: ptchH returned 0x%h (expected 0x56)\n", rd_data[7:0]);
      $stop;
    end
    
    repeat(10) @(posedge clk);
    
    ///////////////////////////////////////////
    // TEST 5: Wait for second INT and read registers from second data entry
    ///////////////////////////////////////////
    $display("TEST 5: Waiting for second INT assertion...");
    
    fork
      begin: timeout2
        repeat(100000) @(posedge clk);
        $display("✗ FAIL: Timeout waiting for second INT\n");
        $stop;
      end
      begin
        @(posedge INT);
        disable timeout2;
      end
    join
    
    $display("Second INT asserted! Reading ptchL register");
    repeat(5) @(posedge clk);
    
    wt_data = 16'hA200;
    wrt = 1;
    @(posedge clk);
    wrt = 0;
    
    @(posedge done);
    repeat(2) @(posedge clk);
    
    // Second entry (@01) pitch=cd0d, so ptchL=0x0d
    if (rd_data[7:0] == 8'h0d) begin
      $display("✓ PASS: Second ptchL returned 0x%h (expected 0x0d)\n", rd_data[7:0]);
    end else begin
      $display("✗ FAIL: Second ptchL returned 0x%h (expected 0x0d)\n", rd_data[7:0]);
      $stop;
    end
    
    repeat(20) @(posedge clk);
    
    ///////////////////////////////////////////
    // All tests passed!
    ///////////////////////////////////////////
    $display("==============================================");
    $display("ALL TESTS PASSED!");
    $display("==============================================");
    $stop;
  end
  
  ///////////////////////////////////////////
  // Timeout watchdog
  ///////////////////////////////////////////
  initial begin
    #5000000;  // 5ms timeout
    $display("\n✗ TESTBENCH TIMEOUT");
    $stop;
  end

endmodule
