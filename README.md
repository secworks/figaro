# figaro
Implementation of the FiGaRO TRNG for FPGAs


## Status
Just started. Does not work. **Do. NOT. Use.**


## Introduction
This repo contains a test implementation of the FiGaRO true random
number generator (TRNG) [1]. The main FPGA target is Lattice iCE40
UltraPlus, but adaption to other FPGAs should be easy to do.

The main challenge is getting the synthesis tool to allow combinational
loops. The combinational loops are located in the firo.v and garo.v
modules. The loops are the source of entropy.


## Implementation details
The implementation instantiates four FiRO and four GaRO modules. The
modules includes state sampling. The polynomials used for the
oscillators are given by equotions (9)..(16) in paper [1]. The eight
outputs are then XORed together to form a one bit random value.

The random bit value is sampled at a rate controlled by a 24 bit
divisor.


### Simulation and linting
The src/sim directory contain a simple simulation model for the cell
instantiated in the combinational loops as inverter. The model is used
during simulation and linting in order to have a functionally complete
design with no black boxes, modules missing.

Verilator will complain on the combinational loops. This is the
expected behaviour.


### Synthesis
The src/synth directory contains additonal modules as well as
constraint files as needed to build a bitstream with an example
design that can be loaded into the FPGA on the
Lattice iCEstick (ICE40HX1K-STICK-EVN).


## Implementation results
### Randomness testing results
Test results from with ENT and PractRand.


### FPGA resource and performance results
TBW.


## References
[1] [True Random Number Generator Based on Fibonacci-Galois
Ring Oscillators for FPGA](https://www.mdpi.com/2076-3417/11/8/3330/pdf)
