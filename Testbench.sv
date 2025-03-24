`timescale 1ns/1ps

// GCD Interface
interface gcd_if(input bit Clk);
    logic [7:0] A_in;
    logic [7:0] B_in;
    logic operands_val;
    logic ack;
    logic [7:0] gcd_out;
    logic gcd_valid;
    logic Rst;

    // Clocking blocks
    clocking cb @(posedge Clk);
        output A_in, B_in, operands_val, ack, Rst;
        input gcd_out, gcd_valid;
    endclocking
endinterface

// Transaction Class
class gcd_packet;
    rand bit [7:0] A;
    rand bit [7:0] B;
    bit operands_valid;

    function new();
        operands_valid = 1'b1;
    endfunction

    // Constraint to make A and B meaningful
    constraint c_valid {
        A inside {[10:200]};  // Avoid trivial cases
        B inside {[10:200]};
    }

    // Displaying the generated packets for debugging
    function void display(string prefix = "");
        $display("%s A = %0d, B = %0d, operands_valid = %0b", prefix, A, B, operands_valid);
    endfunction
  
    // Deep copy method
    function gcd_packet copy();
        gcd_packet pkt_copy = new();
        pkt_copy.A = this.A;
        pkt_copy.B = this.B;
        pkt_copy.operands_valid = this.operands_valid;
        return pkt_copy;
    endfunction
  
endclass

// GCD Function (Golden Model)
function int calc_gcd(input int a, input int b);
    int temp;

    // Special case: if a is 0, return 1

    while (b != 0) begin
        temp = b;
        b = a % b;
        a = temp;
        if (a == 0) 
           return b;
    end
  
    return a;
  
endfunction





// Driver Class
class driver;
    virtual gcd_if vif;
    gcd_packet input_queue[$];

    function new(virtual gcd_if vif, gcd_packet in_q[$]);
        this.vif = vif;
        this.input_queue = in_q;  // Just copy the queue
    endfunction
  
  
    task display_queue(string header = "[DRIVER] Input Queue:");
      $display("%s (Size: %0d)", header, input_queue.size());

      foreach (input_queue[i]) begin
          $display("  Packet[%0d] -> A = %0d, B = %0d, operands_valid = %0d",
                   i, input_queue[i].A, input_queue[i].B, input_queue[i].operands_valid);
      end
  	endtask
  
    task run();
        gcd_packet pkt;

        vif.cb.Rst <= 1;
        repeat (2) @(vif.cb);  // Reset pulse
        vif.cb.Rst <= 0;

        forever begin
            if (!input_queue.empty()) begin
                pkt = input_queue.pop_front();
              	// display_queue("Queue After Pop:");  //Used for debuging

                // Wait random time before sending operands
              	repeat ($urandom_range(1, 5)) @(vif.cb);

                vif.cb.A_in <= pkt.A;
                vif.cb.B_in <= pkt.B;
                vif.cb.operands_val <= pkt.operands_valid;
              	// $display("[%0t] DRIVER: Sent operands A = %0d, B = %0d, asserted operands_val", $time, pkt.A, pkt.B);// Used for debugging
              
                @(vif.cb);  // One clock

                vif.cb.operands_val <= 0;  // De-assert after sending
                @(vif.cb);

                wait (vif.gcd_valid === 1);

                repeat ($urandom_range(1, 5)) @(vif.cb);
                vif.cb.ack <= 1;
                @(vif.cb);
                vif.cb.ack <= 0;

            end else begin
                // Input queue is empty, exit task after a few cycles (optional wait)
                $display("[%0t] DRIVER: Input queue empty, finishing...", $time);
                repeat (5) @(vif.cb);
                break;
            end
        end

        $display("[%0t] DRIVER: Task completed!", $time);
    endtask

endclass




// Monitor and Scoreboard
class monitor;
    virtual gcd_if vif;
    int expect_queue[$];

    function new(virtual gcd_if vif, ref int exp_q[$]);
        this.vif = vif;
        this.expect_queue = exp_q;
    endfunction

    task run();
    int expected;
    bit prev_gcd_valid = 0;

    forever begin
        @(posedge vif.Clk);

        if (vif.gcd_valid === 1 && prev_gcd_valid === 0) begin
            if (expect_queue.empty()) begin
                $display("[%0t] MONITOR: Expect queue empty, nothing to check!", $time);
            end else begin
                expected = expect_queue.pop_front();

                if (vif.gcd_out === expected) begin
                    $display("[PASS] Time=%0t | DUT: %0d Expected: %0d", 
                              $time, vif.gcd_out, expected);
                end else begin
                    $display("[FAIL] Time=%0t | DUT: %0d Expected: %0d", 
                              $time, vif.gcd_out, expected);
                end
            end
        end

        prev_gcd_valid = vif.gcd_valid;

        // Exit when queue is empty
        if (expect_queue.empty()) begin
            $display("[%0t] MONITOR: All transactions checked, finishing...", $time);
            repeat (5) @(posedge vif.Clk);
            break;
        end
    end

    $display("[%0t] MONITOR: Task completed!", $time);
	endtask
endclass







// Testbench Top
module tb_top;
  
    // Clock and reset
    bit Clk;
    always #5 Clk = ~Clk;  // 100MHz clock

    // Interfaces
    gcd_if gcd_vif(Clk);

    // Queues
    gcd_packet input_q[$];
    int expect_q[$];

    // DUT Instance
    top_module dut (
        .A_in(gcd_vif.A_in),
        .B_in(gcd_vif.B_in),
        .operands_val(gcd_vif.operands_val),
        .Clk(Clk),
        .Rst(gcd_vif.Rst),
        .ack(gcd_vif.ack),
        .gcd_out(gcd_vif.gcd_out),
        .gcd_valid(gcd_vif.gcd_valid)
    );

  
    // Driver & Monitor Instances
    driver drv;
    monitor mon;

    initial begin
      
    Clk = 0;
      
	$display("*********************************************************************************");
    $display("******************************SIMULATION STARTED*********************************");
    $display("*********************************************************************************");
      
    // Generate transactions
    repeat (10) begin
        gcd_packet pkt = new();
        pkt.randomize();
        pkt.display("[TB] Generated packet ->");
      input_q.push_back(pkt.copy());

        expect_q.push_back(calc_gcd(pkt.A, pkt.B));  // Directly push the result
      	
    end

    $display("*********************************************************************************");
    $display("******************************PACKETS GENERATED**********************************");
    $display("*********************************************************************************");

    // Create driver and monitor
    drv = new(gcd_vif, input_q);
    mon = new(gcd_vif, expect_q);

    // Fork parallel execution of driver and monitor
    fork
      drv.run();
      mon.run();
    join // Run the simulation till all the active threads are finished (yaaay)

    $display("*********************************************************************************");
    $display("******************************SIMULATION COMPLETED*******************************");
    $display("*********************************************************************************");

    $finish;
      
  end
endmodule
