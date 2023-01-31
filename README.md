# AI Accelerator using FPGA and CDMA

## Introduction
This project's goal is to design fully working FCN accelerator on FPGA using Verilog. We used VIVADO 2020.01ver and VITIS to implement our design. This repository contains major module's code of our full design.

## Full design

![diagram](https://user-images.githubusercontent.com/33273567/215648220-d6fbc950-6d74-465a-abfe-d60de6ad2e01.png)

#### Design diagram
The full activation seqeunce follows
1. Store feature and weight in DDR memory.
2. Send these data to block ram1 and block ram2 using CDMA, respectivly.
3. Send activate signal to FC core in order to proceed FCN calculation.
4. store result in blcok ram.
5. repeat this procedure until the first layer forward pass is done.
6. repeat whole procedure with chaing input to result stored in block ram.

## Block design 
Using VIVADO create an IP using verilog code and create a project to make block desgin of system.
![block diagram](https://user-images.githubusercontent.com/33273567/215675299-fdb3158c-a9fc-4fb9-9bdc-bc657c748985.png)
After connecting whole module, Generate bitstream to run code on VITIS.
