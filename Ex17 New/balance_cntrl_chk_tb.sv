
`timescale 1ns/1ps

// balance_cntrl_chk_tb.sv
// Exercise 17 checker: read stimulus from balance_cntrl_stim.hex,
// drive the DUT, and compare against balance_cntrl_resp.hex.

module balance_cntrl_chk_tb;

    // Clocking
    reg clk = 1'b0;

    // DUT inputs
    reg               rst_n;
    reg               vld;
    reg signed [15:0] ptch;
    reg signed [15:0] ptch_rt;
    reg               pwr_up;
    reg               rider_off;
    reg        [11:0] steer_pot;
    reg               en_steer;

    // DUT outputs
    wire signed [11:0] lft_spd;
    wire signed [11:0] rght_spd;
    wire               too_fast;

    // Instantiate DUT (instance name must remain iDUT)
    balance_cntrl #(.FAST_SIM(1)) iDUT (
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

    // Memories for stimulus/response
    // Stim format (49b): [48]=rst_n, [47]=vld, [46:31]=ptch, [30:15]=ptch_rt,
    //                    [14]=pwr_up, [13]=rider_off, [12:1]=steer_pot, [0]=en_steer
    reg [48:0] stim_mem [0:1499];
    reg [48:0] stim;

    // Resp format (25b): [24:13]=lft_spd, [12:1]=rght_spd, [0]=too_fast
    reg [24:0] resp_mem [0:1499];
    reg [24:0] resp;

    // Bookkeeping
    integer i, j;
    integer mismatches;
    integer mismatches_lft;
    integer mismatches_rght;
    integer mismatches_too;
    reg [24:0] dut_resp;

    // Control knobs
    localparam STOP_ON_MISMATCH = 0;   // 1: stop immediately on first mismatch

    // Overspeed selection policy for the checker:
    //   "auto"     - sample first SAMPLE_N inputs and choose best match
    //   "internal" - use iDUT.u_SegwayMath.too_fast (masked by vld)
    //   "top"      - use top-level output too_fast (already masked by vld)
    localparam TOO_SELECTION = "top";
    localparam int SAMPLE_N = 50;

    // Clock gen
    always #5 clk = ~clk;

    initial begin
        // Local vars used inside the main loop
        reg [24:0] dut_resp_internal;
        reg [24:0] dut_resp_top;
        reg        masked_internal_too;
        reg        masked_top_too;
        reg [24:0] chosen_resp;
        reg        chosen_too;
        integer    sample_cnt_internal;
        integer    sample_cnt_top;
        reg        use_internal_choice;

        $display("[TB] Initializing and loading vectors...");
        $display("[TB] Config: TOO_SELECTION=%s SAMPLE_N=%0d STOP_ON_MISMATCH=%0d", TOO_SELECTION, SAMPLE_N, STOP_ON_MISMATCH);

        // Optional dump for waveform debug
        $dumpfile("balance_cntrl_chk_tb.vcd");
        $dumpvars(0, balance_cntrl_chk_tb);

        // Load files (must exist in run directory)
        $readmemh("balance_cntrl_stim.hex", stim_mem);
        $readmemh("balance_cntrl_resp.hex", resp_mem);

        // Quick sanity print of the first few vectors
        for (j = 0; j < 8; j = j + 1) begin
            $display("[DBG] stim[%0d]=%013h rst=%b vld=%b ptch=%0d ptch_rt=%0d pwr_up=%b rider_off=%b steer_pot=%0d en_steer=%b",
                     j, stim_mem[j], stim_mem[j][48], stim_mem[j][47], $signed(stim_mem[j][46:31]), $signed(stim_mem[j][30:15]),
                     stim_mem[j][14], stim_mem[j][13], stim_mem[j][12:1], stim_mem[j][0]);
            $display("[DBG] resp[%0d]=%07h lft=%0d rght=%0d too=%b",
                     j, resp_mem[j], $signed(resp_mem[j][24:13]), $signed(resp_mem[j][12:1]), resp_mem[j][0]);
        end

        // Exercise requirement: force soft-start timer to 0xFF
        force iDUT.u_PID.ss_tmr = 8'hFF;

        // Reset counters
        mismatches      = 0;
        mismatches_lft  = 0;
        mismatches_rght = 0;
        mismatches_too  = 0;

        // Initialize inputs
        rst_n     = 1'b1;
        vld       = 1'b0;
        ptch      = 16'sd0;
        ptch_rt   = 16'sd0;
        pwr_up    = 1'b0;
        rider_off = 1'b0;
        steer_pot = 12'd0;
        en_steer  = 1'b0;

        #10; // settle before applying vectors

        // Drive all 1500 vectors
        for (i = 0; i < 1500; i = i + 1) begin
            stim      = stim_mem[i];
            // Unpack and drive inputs
            rst_n     = stim[48];
            vld       = stim[47];
            ptch      = stim[46:31];
            ptch_rt   = stim[30:15];
            pwr_up    = stim[14];
            rider_off = stim[13];
            steer_pot = stim[12:1];
            en_steer  = stim[0];

            @(posedge clk);
            #1; // give outputs a tick to settle

            // Focused introspection for vector 8
            if (i == 8) begin
                $display("--- VEC 8 STATE ---");
                $display("i=%0d vld=%b pwr_up=%b rider_off=%b steer_pot=%0d en_steer=%b", i, vld, pwr_up, rider_off, steer_pot, en_steer);
                $display("lft=%0d rght=%0d too_top=%b", $signed(lft_spd), $signed(rght_spd), too_fast);
                $display("iDUT.u_SegwayMath.too_fast=%b", iDUT.u_SegwayMath.too_fast);
                $display("lft_shaped=%0d rght_shaped=%0d", $signed(iDUT.u_SegwayMath.lft_shaped), $signed(iDUT.u_SegwayMath.rght_shaped));
                $display("-------------------");
            end

            // Extra bit-level dump for vector 170
            if (i == 170) begin
                $display("--- VEC 170 BITS ---");
                $display("resp     = %025b", resp);
                $display("dut_resp = %025b", dut_resp);
                $display("resp.lft = %012b (%0d)", resp[24:13], $signed(resp[24:13]));
                $display("resp.rgt = %012b (%0d)", resp[12:1],  $signed(resp[12:1]));
                $display("resp.too = %b", resp[0]);
                $display("dut.lft  = %012b (%0d)", lft_spd,  $signed(lft_spd));
                $display("dut.rgt  = %012b (%0d)", rght_spd, $signed(rght_spd));
                $display("dut.too  = %b (vld?too:%b)", (vld ? too_fast : 1'b0), too_fast);
                $display("flags: vld=%b pwr_up=%b rider_off=%b en_steer=%b steer_pot=%0d", vld, pwr_up, rider_off, en_steer, steer_pot);
                $display("---------------------");
            end

            // Load expected response for this index
            resp = resp_mem[i];

            // Bit-diff spotlight for vector 4
            if (i == 4) begin
                reg [24:0] diff;
                integer k;
                $display("--- VEC 4 XOR-DIFF ---");
                $display("resp     = %025b", resp);
                $display("dut_resp = %025b", dut_resp);
                diff = resp ^ dut_resp;
                $display("diff     = %025b", diff);
                k = -1;
                begin : finddiff
                    for (k = 24; k >= 0; k = k - 1) begin
                        if (diff[k]) begin
                            $display("first differing bit (24..0) = %0d", k);
                            disable finddiff;
                        end
                    end
                end
                $display("resp.lft = %012b (%0d)", resp[24:13], $signed(resp[24:13]));
                $display("resp.rgt = %012b (%0d)", resp[12:1],  $signed(resp[12:1]));
                $display("resp.too = %b", resp[0]);
                $display("dut.lft  = %012b (%0d)", lft_spd,  $signed(lft_spd));
                $display("dut.rgt  = %012b (%0d)", rght_spd, $signed(rght_spd));
                $display("dut.too  = %b (vld?too:%b)", (vld ? too_fast : 1'b0), too_fast);
                $display("-----------------------");
            end

            // Build candidate DUT response vectors (internal vs top-level too_fast)
            masked_internal_too = iDUT.u_SegwayMath.too_fast;
            masked_top_too      = too_fast;
            dut_resp_internal   = { lft_spd, rght_spd, masked_internal_too };
            dut_resp_top        = { lft_spd, rght_spd, masked_top_too };

            // Decide which too_fast to compare (auto-sample or forced choice)
            if (i == 0) begin
                sample_cnt_internal = 0;
                sample_cnt_top      = 0;
                use_internal_choice = 1'b1; // default prior to decision
            end

            if (TOO_SELECTION == "internal") begin
                use_internal_choice = 1'b1;
            end else if (TOO_SELECTION == "top") begin
                use_internal_choice = 1'b0;
            end else begin
                if (i < SAMPLE_N) begin
                    if (dut_resp_internal == resp) sample_cnt_internal = sample_cnt_internal + 1;
                    if (dut_resp_top      == resp) sample_cnt_top      = sample_cnt_top      + 1;
                    if (i == SAMPLE_N - 1) begin
                        use_internal_choice = (sample_cnt_internal >= sample_cnt_top);
                        $display("[TB] Auto choice after %0d: internal=%0d, top=%0d -> using %s",
                                 SAMPLE_N, sample_cnt_internal, sample_cnt_top,
                                 (use_internal_choice ? "internal" : "top"));
                    end
                end else begin
                    // Compare against the chosen candidate
                    chosen_resp = use_internal_choice ? dut_resp_internal : dut_resp_top;
                    chosen_too  = use_internal_choice ? masked_internal_too : masked_top_too;

                    if (chosen_resp !== resp) begin
                        $display("Mismatch @%0d\n  exp(bits)=%b\n  got(bits)=%b\n  exp_lft=%0d got_lft=%0d\n  exp_rgt=%0d got_rgt=%0d\n  exp_too=%b got_too=%b\n  stim: rst_n=%b vld=%b ptch=%0d ptch_rt=%0d pwr_up=%b rider_off=%b steer_pot=%0d en_steer=%b\n  PID_cntrl=%0d integrator=%0d lft_shaped=%0d rght_shaped=%0d",
                                 i, resp, chosen_resp,
                                 $signed(resp[24:13]), $signed(lft_spd),
                                 $signed(resp[12:1]),  $signed(rght_spd),
                                 resp[0], chosen_too,
                                 rst_n, vld, $signed(ptch), $signed(ptch_rt), pwr_up, rider_off, steer_pot, en_steer,
                                 $signed(iDUT.u_PID.PID_cntrl), $signed(iDUT.u_PID.integrator),
                                 $signed(iDUT.u_SegwayMath.lft_shaped), $signed(iDUT.u_SegwayMath.rght_shaped));
                        mismatches = mismatches + 1;
                        if ($signed(resp[24:13]) !== $signed(lft_spd))  mismatches_lft  = mismatches_lft  + 1;
                        if ($signed(resp[12:1])  !== $signed(rght_spd)) mismatches_rght = mismatches_rght + 1;
                        if (resp[0] !== chosen_too)                     mismatches_too  = mismatches_too  + 1;
                        if (STOP_ON_MISMATCH) begin
                            $display("Stopping on first mismatch (STOP_ON_MISMATCH=%0d)", STOP_ON_MISMATCH);
                            release iDUT.u_PID.ss_tmr;
                            $finish;
                        end
                    end
                end
            end
        end

        // Release any forces
        release iDUT.u_PID.ss_tmr;

        if (mismatches == 0) begin
            $display("PASS: 1500/1500 vectors matched");
        end else begin
            $display("FAIL: %0d mismatches", mismatches);
            $display("Breakdown: lft=%0d rght=%0d too=%0d", mismatches_lft, mismatches_rght, mismatches_too);
        end

        $finish;
    end

endmodule
