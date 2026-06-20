# Memory Management Unit (MMU) Design Using Verilog HDL

## Overview

This project implements a Memory Management Unit (MMU) using Verilog HDL. The design models key memory-management components commonly used in modern processors, including address translation, translation lookaside buffers (TLB), page table walking, permission checking, and control/status registers.

The design was functionally verified using Icarus Verilog and analyzed using GTKWave waveform visualization.

---

## Features

* Virtual-to-Physical Address Translation
* Translation Lookaside Buffer (TLB)
* 4-Way Set Associative TLB
* Pseudo-LRU Replacement Policy
* Page Table Walker (PTW) FSM
* Permission Checking Logic
* CSR Register Interface
* Modular RTL Design
* Functional Verification
* GTKWave Waveform Analysis

---

## RTL Modules

* mmu_top.v
* tlb_4way_plru.v
* ptw_fsm.v
* pt_memory_model.v
* address_translator.v
* permission_checker.v
* csr_registers.v

---

## Verification

The MMU was verified using a dedicated testbench:

* mmu_top_tb.v

Verified functionality:

* Address Translation
* TLB Lookup Operations
* Page Table Walk Requests
* Permission Validation
* Fault Handling
* Request/Response Transactions

---

## Project Structure

rtl/
tb/
waveforms/
docs/
reports/
constraints/

---

## Tools Used

* Verilog HDL
* Icarus Verilog
* GTKWave

---

## Waveform Results

* mmu_request_response.png
* mmu_translation_waveform.png

---

## Learning Outcomes

* Computer Architecture Concepts
* Memory Management Techniques
* TLB Design
* Page Table Walking
* FSM Design
* RTL Verification
* Digital System Design

---

## Author

Jatin Gujarathi

Final Year B.Tech Student

Areas of Interest:

* VLSI Design
* FPGA Design
* RTL Design
* Functional Verification
* Computer Architecture
