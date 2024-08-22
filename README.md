# AHB_to_APB
This project involves the design and implementation of an AHB (Advanced High-performance Bus) to APB (Advanced Peripheral Bus) bridge converter. The bridge facilitates communication between a high-speed AHB and a lower-speed APB, ensuring efficient data transfer between the two buses in a SoC (System on Chip) environment.

# Key Features:
Protocol Conversion: Converts the high-performance, pipelined AHB protocol to the simpler, low-power APB protocol, enabling peripheral access.
Data Transfer Optimization: Efficiently handles different clock domains and data widths, ensuring seamless integration with peripheral devices.
Interface Design: Includes an intuitive interface for connecting various peripheral devices to the AHB-based master modules.
Verification: A comprehensive testbench was created to validate the bridge's functionality under various operational scenarios.
# Tools & Technologies Used:
Hardware Description Language: Verilog/SystemVerilog for RTL design.
Simulation Tools: ModelSim for simulation and verification.
Synthesis Tools: Synopsys Design Compiler for synthesis and timing analysis.
Version Control: Git is used to manage and track code changes.
# Project Outcomes:
Successfully designed and verified the AHB to APB bridge converter with all intended functionalities.
Demonstrated the bridge's ability to efficiently manage communication between different bus protocols, making it a robust solution for SoC designs.
