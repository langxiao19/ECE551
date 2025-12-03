module A2D_intf(
  input        clk,
  input        rst_n,
  input        nxt,          // Trigger next A2D conversion (from vld signal)
  input        MISO,         // SPI data from A2D
  output [11:0] lft_ld,       // Left load cell reading
  output [11:0] rght_ld,      // Right load cell reading
  output [11:0] batt,         // Battery voltage reading
  output [11:0] steer_pot,    // Steering potentiometer reading
  output       SS_n,         // SPI slave select
  output       SCLK,         // SPI clock
  output       MOSI          // SPI data to A2D
);

  ///////////////////////////////////////////////////
  // Internal signals                              //
  ///////////////////////////////////////////////////
  logic [15:0] wt_data;       // Command to send via SPI
  logic        wrt;           // Initiate SPI transaction
  logic        done;          // SPI transaction complete
  logic [15:0] rd_data;       // Data read from SPI
  
  logic [2:0] channel;        // Current channel being read
  logic [2:0] update_sel;     // Which register to update (combinational)
  logic [2:0] update_sel_ff;  // Registered version for timing
  
  logic [11:0] lft_ld_ff, rght_ld_ff, batt_ff, steer_pot_ff;
  
  ///////////////////////////////////////////////////
  // State machine                                 //
  ///////////////////////////////////////////////////
  typedef enum logic [3:0] {
    IDLE,
    CH0,           // Start CH0 (left load)
    WAIT1,         // Wait for CH0 to complete
    CH1,           // Start CH1 (right load)
    WAIT2,         // Wait for CH1 to complete
    CH2,           // Start CH2 (battery)
    WAIT3,         // Wait for CH2 to complete  
    CH4,           // Start CH4 (steer pot)
    WAIT4          // Wait for CH4 to complete
  } state_t;
  
  state_t state, nxt_state;
  
  ///////////////////////////////////////////////////
  // Round-robin state machine                     //
  ///////////////////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      state <= IDLE;
    else
      state <= nxt_state;
  end
  
  always_comb begin
    // Defaults
    nxt_state = state;
    wrt = 1'b0;
    channel = 3'b000;
    update_sel = 3'b000;
    
    case (state)
      IDLE: begin
        if (nxt) begin
          nxt_state = CH0;
        end
      end
      
      CH0: begin
        wrt = 1'b1;
        channel = 3'b000;  // Read left load cell (channel 0)
        nxt_state = WAIT1;
      end
      
      WAIT1: begin
        if (done) begin
          nxt_state = CH1;
          update_sel = 3'b001;  // Update left load cell from completed read
        end
      end
      
      CH1: begin
        wrt = 1'b1;
        channel = 3'b100;  // Read right load cell (channel 4)
        nxt_state = WAIT2;
      end
      
      WAIT2: begin
        if (done) begin
          nxt_state = CH2;
          update_sel = 3'b010;  // Update right load cell
        end
      end
      
      CH2: begin
        wrt = 1'b1;
        channel = 3'b101;  // Read steering pot (channel 5)
        nxt_state = WAIT3;
      end
      
      WAIT3: begin
        if (done) begin
          nxt_state = CH4;
          update_sel = 3'b100;  // Update steering pot
        end
      end
      
      CH4: begin
        wrt = 1'b1;
        channel = 3'b110;  // Read battery (channel 6)
        nxt_state = WAIT4;
      end
      
      WAIT4: begin
        if (done) begin
          nxt_state = IDLE;
          update_sel = 3'b011;  // Update battery
        end
      end
      
      default: nxt_state = IDLE;
    endcase
  end
  
  ///////////////////////////////////////////////////
  // Register update_sel for proper timing         //
  ///////////////////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      update_sel_ff <= 3'b000;
    else
      update_sel_ff <= update_sel;
  end
  
  ///////////////////////////////////////////////////
  // Update output registers                       //
  ///////////////////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      lft_ld_ff <= 12'h000;
      rght_ld_ff <= 12'h000;
      batt_ff <= 12'h000;
      steer_pot_ff <= 12'h000;
    end else begin
      case (update_sel_ff)
        3'b001: lft_ld_ff <= rd_data[11:0];
        3'b010: rght_ld_ff <= rd_data[11:0];
        3'b011: batt_ff <= rd_data[11:0];
        3'b100: steer_pot_ff <= rd_data[11:0];
        default: ;
      endcase
    end
  end
  
  assign lft_ld = lft_ld_ff;
  assign rght_ld = rght_ld_ff;
  assign batt = batt_ff;
  assign steer_pot = steer_pot_ff;
  
  ///////////////////////////////////////////////////
  // Build command word for ADC128S                //
  ///////////////////////////////////////////////////
  assign wt_data = {3'b000, channel, 11'h000};  // Channel selection in bits [13:11]
  
  ///////////////////////////////////////////////////
  // Instantiate SPI monarch                       //
  ///////////////////////////////////////////////////
  SPI_mnrch iSPI(
    .clk(clk),
    .rst_n(rst_n),
    .wrt(wrt),
    .wt_data(wt_data),
    .done(done),
    .rd_data(rd_data),
    .SS_n(SS_n),
    .SCLK(SCLK),
    .MOSI(MOSI),
    .MISO(MISO)
  );

endmodule
