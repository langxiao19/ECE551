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
    
    $display("========================================");
    $display("SPI Monarch Testbench - Started");
    $display("========================================\n");
    
    /////////////////////////////////////////////
    // Test 1: Verify WHO_AM_I register read
    // Read from address 0x0F, expect 0x6A back
    /////////////////////////////////////////////
    $display("[Test 1] Reading WHO_AM_I (addr 0x0F)");
    wt_data = 16'h8F00;  // Read command: MSB=1, address=0x0F
    wrt = 1;
    @(posedge clk);
    wrt = 0;
    
    // Wait for SPI transaction completion
    @(posedge done);
    @(posedge clk);
    
    // Verify WHO_AM_I value
    if (rd_data[7:0] == 8'h6A) begin
      $display("  [PASS] WHO_AM_I = 0x%h\n", rd_data[7:0]);
    end else begin
      $display("  [FAIL] WHO_AM_I = 0x%h, expected 0x6A\n", rd_data[7:0]);
      $stop;
    end
    
    repeat(8) @(posedge clk);
    
    /////////////////////////////////////////////
    // Test 2: Configure interrupt enable
    // Write 0x02 to register 0x0D
    /////////////////////////////////////////////
    $display("[Test 2] Configuring INT enable (write 0x02 to 0x0D)");
    wt_data = 16'h0D02;  // Write command: MSB=0, address=0x0D, data=0x02
    wrt = 1;
    @(posedge clk);
    wrt = 0;
    
    // Wait for completion
    @(posedge done);
    repeat(3) @(posedge clk);
    
    // Verify sensor configuration completed
    if (iNEMO.NEMO_setup) begin
      $display("  [PASS] Sensor configured for interrupts\n");
    end else begin
      $display("  [FAIL] Sensor configuration failed\n");
      $stop;
    end
    
    repeat(8) @(posedge clk);
    
    /////////////////////////////////////////////
    // Test 3: Wait for interrupt, then read pitch low byte
    // First data entry in inert_data.hex has pitch=0x5663
    /////////////////////////////////////////////
    $display("[Test 3] Waiting for INT signal...");
    
    // Wait for INT with timeout protection
    fork
      begin: int_wait_timeout
        repeat(100000) @(posedge clk);
        $display("  [FAIL] INT timeout\n");
        $stop;
      end
      begin
        @(posedge INT);
        disable int_wait_timeout;
      end
    join
    
    $display("  INT detected! Reading pitch low byte (0xA2)");
    repeat(3) @(posedge clk);
    
    wt_data = 16'hA200;  // Read ptchL register
    wrt = 1;
    @(posedge clk);
    wrt = 0;
    
    @(posedge done);
    @(posedge clk);
    
    // First entry: pitch = 0x5663, so low byte = 0x63
    if (rd_data[7:0] == 8'h63) begin
      $display("  [PASS] ptchL = 0x%h", rd_data[7:0]);
    end else begin
      $display("  [FAIL] ptchL = 0x%h, expected 0x63", rd_data[7:0]);
      $stop;
    end
    
    // Verify INT cleared after read
    if (!INT) begin
      $display("  [PASS] INT deasserted after read\n");
    end else begin
      $display("  [FAIL] INT still asserted\n");
      $stop;
    end
    
    repeat(8) @(posedge clk);
    
    /////////////////////////////////////////////
    // Test 4: Read pitch high byte
    /////////////////////////////////////////////
    $display("[Test 4] Reading pitch high byte (0xA3)");
    wt_data = 16'hA300;  // Read ptchH register
    wrt = 1;
    @(posedge clk);
    wrt = 0;
    
    @(posedge done);
    @(posedge clk);
    
    // First entry: pitch = 0x5663, so high byte = 0x56
    if (rd_data[7:0] == 8'h56) begin
      $display("  [PASS] ptchH = 0x%h (full pitch = 0x5663)\n", rd_data[7:0]);
    end else begin
      $display("  [FAIL] ptchH = 0x%h, expected 0x56\n", rd_data[7:0]);
      $stop;
    end
    
    repeat(8) @(posedge clk);
    
    /////////////////////////////////////////////
    // Test 5: Verify second interrupt and data
    // Second entry has pitch=0xcd0d
    /////////////////////////////////////////////
    $display("[Test 5] Waiting for next INT...");
    
    fork
      begin: int_wait_timeout2
        repeat(100000) @(posedge clk);
        $display("  [FAIL] Second INT timeout\n");
        $stop;
      end
      begin
        @(posedge INT);
        disable int_wait_timeout2;
      end
    join
    
    $display("  Second INT received! Reading ptchL again");
    repeat(3) @(posedge clk);
    
    wt_data = 16'hA200;
    wrt = 1;
    @(posedge clk);
    wrt = 0;
    
    @(posedge done);
    @(posedge clk);
    
    // Second entry: pitch = 0xcd0d, so low byte = 0x0d
    if (rd_data[7:0] == 8'h0d) begin
      $display("  [PASS] Second ptchL = 0x%h\n", rd_data[7:0]);
    end else begin
      $display("  [FAIL] Second ptchL = 0x%h, expected 0x0d\n", rd_data[7:0]);
      $stop;
    end
    
    repeat(15) @(posedge clk);
    
    /////////////////////////////////////////////
    // Test complete
    /////////////////////////////////////////////
    $display("========================================");
    $display("All Tests Completed Successfully!");
    $display("========================================");
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
