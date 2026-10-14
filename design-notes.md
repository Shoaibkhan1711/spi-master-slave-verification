# SPI Design Notes

## Mode 0 timing

Mode 0 uses CPOL=0 and CPHA=0. SCLK is low while idle. The receiver samples data on rising SCLK edges, and the transmitter changes data on falling SCLK edges. The most-significant bit is transmitted first.

## Full-duplex operation

MOSI carries data from master to slave. MISO carries data from slave to master. Both directions operate during the same eight SCLK sampling edges. Therefore, the master's received byte should equal the slave's transmitted byte, and the slave's received byte should equal the master's transmitted byte.

## Master clock divider

The master generates SCLK by toggling it after a divider interval while a transfer is active. With the intended divider scheme, the SCLK frequency is approximately the system clock frequency divided by `2 * CLK_DIV`.

## Testbench

The testbench drives a reset, runs directed values, checks `0x00` and `0xFF` corner cases, then runs 20 randomized byte pairs. The scoreboard compares both receive paths against the opposite side's transmit value. Immediate assertions check selected protocol properties.

## Review before production use

Review edge timing at the start and end of a frame, MISO preload timing, reset behavior, assertion semantics, and synthesis support in the target tool. Run simulation and inspect waveforms before relying on the design.
