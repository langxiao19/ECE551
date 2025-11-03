module SPI_mnrch(
  input clk,              // 50MHz system clock
  input rst_n,            // active low reset
  input wrt,              // high for 1 clock initiates SPI transaction
  input MISO,             // Monarch In Serf Out
  input [15:0] wt_data,   // data to write (command) to serf
  output SS_n,            // active low serf select
  output SCLK,            // serial clock
  output MOSI,            // Monarch Out Serf In
  output done,            // asserted when transaction complete
  output [15:0] rd_data   // data read from serf
);

  ///////////////////////////////////////////
  // Define states for SPI monarch state machine
  ///////////////////////////////////////////
  typedef enum reg [1:0] {IDLE, LOAD, SHIFT, BACK_PORCH} state_t;
  
  ///////////////////////////////////////////
  // Internal signals
  ///////////////////////////////////////////
  state_t state, nxt_state;
  reg [3:0] SCLK_div;      // 4-bit counter for SCLK generation
  reg [15:0] shft_reg;     // 16-bit shift register
  reg [4:0] bit_cntr;      // bit counter (needs to count to 16)
  reg MISO_smpl;           // sampled version of MISO
  reg done_ff;             // flop for done signal
  reg SS_n_ff;             // flop for SS_n signal
  
  ///////////////////////////////////////////
  // State machine signals
  ///////////////////////////////////////////
  logic init;              // initialize shift register and counters
  logic shft;              // shift enable
  logic ld_SCLK;           // load SCLK_div with 4'b1011
  logic set_done;          // set done signal
  
  ///////////////////////////////////////////
  // SCLK_div counter - creates SCLK
  // Load with 1011 for front porch
  // Count when not loading
  ///////////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      SCLK_div <= 4'b1011;
    else if (ld_SCLK)
      SCLK_div <= 4'b1011;
    else
      SCLK_div <= SCLK_div + 1;
  end
  
  // SCLK comes from MSB of SCLK_div
  assign SCLK = SCLK_div[3]; 
  ///////////////////////////////////////////
  // Shift register - parallel load and shift
  // Shifts on SCLK fall (when SCLK_div == 4'b1111)
  ///////////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      shft_reg <= 16'h0000;
    else if (init)
      shft_reg <= wt_data;
    else if (shft)
      shft_reg <= {shft_reg[14:0], MISO_smpl};
  end
  
  ///////////////////////////////////////////
  // Sample MISO on SCLK rise (when SCLK_div == 4'b0111)
  ///////////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      MISO_smpl <= 1'b0;
    else if (SCLK_div == 4'b0111)
      MISO_smpl <= MISO;
  end
  
  ///////////////////////////////////////////
  // Bit counter - counts number of shifts
  ///////////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      bit_cntr <= 5'h00;
    else if (init)
      bit_cntr <= 5'h00;
    else if (shft)
      bit_cntr <= bit_cntr + 1;
  end
  
  /////////////////////////////////////////////////////////////////
  // Done flag generation
  /////////////////////////////////////////////////////////////////
  // Flop that holds completion status
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      done_ff <= 1'b0;
    else if (set_done)  // Asserted in BACK_PORCH when transaction completes
      done_ff <= 1'b1;
    else if (init)  // Cleared when new transaction initiated
      done_ff <= 1'b0;
  end
  
  // Transaction tracking latch - Set/Reset latch behavior
  // Latch allows combinational response (no clock edge delay)
  logic in_transaction, trans_set, trans_rst;
  
  assign trans_set = init;                    // Set when wrt detected in IDLE
  assign trans_rst = set_done | ~rst_n;       // Clear when transaction done
  
  always_latch begin
    if (trans_rst)
      in_transaction = 1'b0;
    else if (trans_set)
      in_transaction = 1'b1;
  end
  
  // Final done output: high only when done_ff set and no active transaction
  assign done = done_ff & ~in_transaction;
  
  ///////////////////////////////////////////
  // SS_n signal - implemented with preset flop
  // Goes low during transaction
  ///////////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      SS_n_ff <= 1'b1;
    else if (init)
      SS_n_ff <= 1'b0;
    else if (set_done)
      SS_n_ff <= 1'b1;
  end
  
  assign SS_n = SS_n_ff;
  
  ///////////////////////////////////////////
  // State machine - sequential logic
  ///////////////////////////////////////////
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n)
      state <= IDLE;
    else
      state <= nxt_state;
  end
  
  ///////////////////////////////////////////
  // State machine - combinational logic
  ///////////////////////////////////////////
  always_comb begin
    // Default outputs
    init = 1'b0;
    shft = 1'b0;
    ld_SCLK = 1'b0;
    set_done = 1'b0;
    nxt_state = state;
    
    case (state)
      IDLE: begin
        ld_SCLK = 1'b1;  // Keep SCLK_div at 1011 (SCLK high)
        if (wrt) begin
          init = 1'b1;
          nxt_state = LOAD;
        end
      end
      
      LOAD: begin
        // Front porch - Wait for first SCLK fall but don't shift yet
        // This creates the delay from SS_n fall to first meaningful SCLK cycle
        if (SCLK_div == 4'b1111) begin
          // First SCLK fall occurred, now move to shifting state
          nxt_state = SHIFT;
        end
      end
      
      SHIFT: begin
        // Shift on SCLK fall (SCLK_div == 4'b1111)  
        // This shifts in the bit that was sampled on the previous SCLK rise
        if (SCLK_div == 4'b1111) begin
          shft = 1'b1;
          // After 15 shifts (bit_cntr goes from 0 to 14), move to back porch
          if (bit_cntr == 5'd14) begin
            nxt_state = BACK_PORCH;
          end
        end
      end
      
      BACK_PORCH: begin
        // Do the 16th shift, then raise SS_n before the next SCLK negedge
        // This ensures NEMO's write_reg is still asserted for writes
        if (SCLK_div == 4'b0111) begin
          // About to have SCLK rise (16th rise) - sample MISO
        end else if (SCLK_div == 4'b1110) begin
          // SCLK is high, about to fall - do final shift and then raise SS_n
          shft = 1'b1;  // 16th shift
          ld_SCLK = 1'b1;  // Prevent SCLK from falling again
          set_done = 1'b1; // Raise SS_n
          nxt_state = IDLE;
        end
      end
      
      default: nxt_state = IDLE;
    endcase
  end
  
  ///////////////////////////////////////////
  // Output assignments
  ///////////////////////////////////////////
  assign MOSI = shft_reg[15];
  assign rd_data = shft_reg;

endmodule
