# figaro
Implementation of the FiGaRO TRNG for FPGAs


## Status
Just started. Does not work. **Do. NOT Use**


## Introduction
This repo contains (will contain) a test implementation of the FiGaRO
true random number generator (TRNG) [1]. The main target is Lattice iCE40
FPGAs.


## Implementation details
The implementation instantiates four FiRO and four GaRO modules. The
modules includes state sampling. The polynomials used are given by
equotions (9)..(16) in paper [1]. The eight outputs are then XORed
together to form a one bit sample value. The sample rate is controlled
by a 24 bit divisor.


## Implementation results
### Randomness testing results
Tests with ENT and PractRand.


### FPGA resource and performance results
TBW.


## References
[1] [True Random Number Generator Based on Fibonacci-Galois
Ring Oscillators for FPGA](https://www.mdpi.com/2076-3417/11/8/3330/pdf)
