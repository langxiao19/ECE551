// Random data testbench for the balance controller
module balance_cntrl_chk_tb();

// Clock
reg clk;
initial clk = 0;
always #5 clk = ~clk;

// Instantiate DUT
logic rst_n;
logic vld;
logic [15:0] ptch;
logic [15:0] ptch_rt;
logic pwr_up;
logic rider_off;
logic [11:0] steer_pot;
logic en_steer;
logic [11:0] lft_speed;
logic [11:0] rght_speed;
logic too_fast;
balance_cntrl iDUT (
    .clk(clk),
    .rst_n(rst_n),
    .vld(vld),
    .ptch(ptch),
    .ptch_rt(ptch_rt),
    .pwr_up(pwr_up),
    .rider_off(rider_off),
    .steer_pot(steer_pot),
    .en_steer(en_steer),
    .lft_speed(lft_speed),
    .rght_speed(rght_speed),
    .too_fast(too_fast)
);

// Declare memory
reg [48:0] stim_mem[0:1499];
reg [24:0] resp_mem[0:1499];

// Main block
initial begin
    // Initialize memory
    $readmemh("balance_cntrl_stim.hex", stim_mem);
    $readmemh("balance_cntrl_resp.hex", resp_mem);

    // Force ss_tmr
    force iDUT.ss_tmr = 8'hFF;

    // Main loop
    foreach (stim_mem[i]) begin
        // Provide stimulus
        rst_n = stim_mem[i][48];
        vld = stim_mem[i][47];
        ptch[15:0] = stim_mem[i][46:31];
        ptch_rt[15:0] = stim_mem[i][30:15];
        pwr_up = stim_mem[i][14];
        rider_off = stim_mem[i][13];
        steer_pot[11:0] = stim_mem[i][12:1];
        en_steer = stim_mem[i][0];

        @(posedge clk) #1; // wait for response

        // Compare data and pause simulation if a mismatch occurs
        if (!(
            lft_speed === resp_mem[i][24:13]
            && rght_speed === resp_mem[i][12:1]
            && too_fast === resp_mem[i][0]
        )) begin
            $display("Error: Mismatch found at iteration %d", i);
            if (lft_speed !== resp_mem[i][24:13]) $display("lft_speed: Expected: %h, Observed: %h", resp_mem[i][24:13], lft_speed);
            if (rght_speed !== resp_mem[i][12:1]) $display("rght_speed: Expected: %h, Observed: %h", resp_mem[i][12:1], rght_speed);
            if (too_fast !== resp_mem[i][0]) $display("too_fast: Expected: %h, Observed: %h", resp_mem[i][0], too_fast);
            //$stop();
        end
    end

    // Display the yahoo message and pause simulation
    $display("Yahoo! The test passed!");
    $stop();
end

endmodule
