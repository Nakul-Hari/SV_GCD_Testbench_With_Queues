# Class and Queue-Based GCD Testbench

This project demonstrates a **SystemVerilog-based testbench** architecture for verifying a **Greatest Common Divisor (GCD)** hardware module. The testbench has been enhanced to use **classes and queues** to enable modularity, reusability, and better stimulus management.

---

## Project Overview

The primary goal of this project is to create a **class-based and queue-based** testbench that verifies the functionality of a GCD computation module. The testbench uses randomized test vectors, a golden reference model, and automated checking mechanisms.

---

## Features

-  **Transaction Class (`gcd_packet`)**
-  **Input and Expected Output Queues**
-  **Golden Reference Model (`calc_gcd()` function)**
-  **Driver and Monitor Classes**
-  **Clocking Blocks and Interfaces (`gcd_if`)**
-  **Random Delays and Handshaking with the DUT**
-  **Automated Scoreboarding**
-  **Synopsys VCS Simulation Logs and Results**

---

## Testbench Architecture

The testbench consists of the following key components:

| Component            | Description                                                                                   |
|----------------------|-----------------------------------------------------------------------------------------------|
| **Interface (`gcd_if`)**      | Groups all DUT signals and provides a structured connection using clocking blocks.         |
| **Transaction Class (`gcd_packet`)** | Holds operands A and B and manages randomization with constraints.                      |
| **Golden Model (`calc_gcd()`)** | Computes reference GCD values using the Euclidean algorithm.                              |
| **Driver Class**     | Drives stimulus to the DUT by reading from the input queue and managing handshaking signals.  |
| **Monitor & Scoreboard** | Verifies DUT output against expected results from the expect queue and reports pass/fail.     |
| **Testbench Top (`tb_top`)** | Instantiates all components, generates clock, drives simulation flow, and reports results. |

---

## Key Components Explained

### GCD Interface (`gcd_if`)

- Groups DUT signals: `A_in`, `B_in`, `operands_val`, `ack`, `gcd_out`, `gcd_valid`, `Rst`.
- Contains a `clocking block` for synchronized signal interaction.
- Provides a clean and organized communication channel between the testbench and DUT.

### Transaction Class (`gcd_packet`)

- Contains randomized 8-bit operands `A` and `B`.
- Includes a constraint block to generate meaningful values (range: 10 to 200).
- Provides `copy()` and `display()` methods for debugging and safe queue operations.

### Golden Model (`calc_gcd()`)

- Implements the Euclidean algorithm.
- Provides reliable reference GCD results for verification.

### Driver

- Reads `gcd_packet` objects from the input queue.
- Applies inputs to the DUT through the `gcd_if` interface.
- Manages `operands_val` and `ack` signals.
- Waits for random time intervals to simulate asynchronous behavior.

### Monitor & Scoreboard

- Continuously monitors the `gcd_valid` signal.
- Pops expected GCD values from the `expect_queue`.
- Compares DUT outputs with expected results and logs `[PASS]` or `[FAIL]`.

---

## Testbench Flow

1. **Randomized Packets Generation**
   - Random operands A and B are generated.
   - Each packet is pushed into the `input_queue`.
   - Corresponding expected GCD results are computed using `calc_gcd()` and pushed into the `expect_queue`.

2. **Driver and Monitor Operation**
   - The driver sends packets to the DUT from the `input_queue`.
   - The monitor checks DUT outputs against the expected values from the `expect_queue`.

3. **Simulation Control**
   - Clock generation at 100MHz (Clk toggles every 5 time units).
   - Simulation ends after all transactions are verified.

---

## Simulation Log & Results

The simulation was executed using **Synopsys VCS**. The terminal output includes:

- Packet generation log:
  ```
  [TB] Generated packet -> A = 15, B = 30, operands_valid = 1
  [TB] Generated packet -> A = 42, B = 187, operands_valid = 1
  ...
  ```

- Verification log:
  ```
  [PASS] Time=95000 | DUT: 15 Expected: 15
  [PASS] Time=365000 | DUT: 1 Expected: 1
  [PASS] Time=625000 | DUT: 1 Expected: 1
  ...
  ```

- All transactions pass, confirming DUT correctness for the tested input range.

---

## How to Run

1. **Setup**
   - Install Synopsys VCS (or other supported SystemVerilog simulators).

2. **Compile**
   ```bash
   vcs -sverilog -debug_all tb_top.sv gcd_if.sv gcd_packet.sv driver.sv monitor.sv calc_gcd.sv top_module.sv
   ```

3. **Simulate**
   ```bash
   ./simv
   ```

4. **Check Results**
   - Verify `[PASS]` messages in the terminal output.

---

## Conclusion
This testbench design demonstrates a structured and scalable approach to hardware verification using **SystemVerilog classes**, **queues**, and **interfaces**. It ensures robust testing through randomized stimulus, reference model checking, and automated scoreboarding.


## License
This project is licensed under the [MIT License](LICENSE).


## Acknowledgments
This implementation is part of the course work for EE5530 Principles of SoC Functional Verification

