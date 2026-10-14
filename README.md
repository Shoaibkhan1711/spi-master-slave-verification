# SPI Master–Slave Design and Verification

A compact SystemVerilog SPI Mode 0 master–slave design demonstrating full-duplex serial transfer, a configurable master clock divider, a parameterized data width, a self-checking testbench, directed corner cases, randomized transfers, and protocol assertions.

## Repository structure

```text
.
├── rtl/
│   ├── spi_master.sv
│   ├── spi_slave.sv
│   └── spi_top.sv
├── tb/
│   └── spi_tb.sv
├── sim/
│   └── run_iverilog.sh
├── docs/
│   └── design-notes.md
├── .gitignore
└── README.md
```

## SPI mode

This design targets **SPI Mode 0**:
- CPOL = 0: SCLK idles low.
- CPHA = 0: data is sampled on rising SCLK edges.
- MOSI changes on falling SCLK edges.
- SS is active low.

The master and slave exchange data simultaneously, so each side receives the byte transmitted by the other side.

## Modules

- `spi_master.sv`: Master FSM, clock divider, transmit/receive shift registers, `busy`, and `done`.
- `spi_slave.sv`: Slave transmit/receive shift registers, MOSI sampling, and MISO update.
- `spi_top.sv`: Connects one master and one slave.
- `spi_tb.sv`: Reset, directed transfers, `0x00`/`0xFF` corner values, 20 randomized transfers, scoreboard checks, and immediate assertions.

## Run with Icarus Verilog

Install Icarus Verilog, then run:

```bash
bash sim/run_iverilog.sh
```

Or compile manually:

```bash
mkdir -p build
iverilog -g2012 -Wall -s spi_tb -o build/spi_sim \
  rtl/spi_master.sv rtl/spi_slave.sv rtl/spi_top.sv tb/spi_tb.sv
vvp build/spi_sim
```

The testbench writes `spi.vcd`, which can be opened with GTKWave.

## Run with Vivado

Add the three files in `rtl/` as design sources and `tb/spi_tb.sv` as a simulation source. Set `spi_tb` as the simulation top and run Behavioral Simulation. Check the simulator console for PASS/FAIL output and inspect `spi.vcd` or the Vivado waveform.

## Scope and limitations

- The top-level connects one master to one slave for demonstration and verification.
- The design is an educational RTL project, not a production-qualified SPI IP.
- Simulation results should be confirmed in the target simulator before claiming all tests pass.
- Review synthesis support for immediate assertions and event-control constructs in the selected tool.
- The design currently targets the 8-bit use case shown in the testbench. If changing `DATA_WIDTH`, review all shift slices and counter sizing.

## Verification scenarios

1. Reset behavior
2. Directed full-duplex transfer (`0xA5` and `0x3C`)
3. Corner cases (`0x00` and `0xFF`)
4. Twenty randomized master/slave byte pairs
5. Scoreboard comparison of both receive paths
6. Assertions for slave-select behavior, `done` pulse width, clock enable while deselected, and unknown MOSI/MISO values

## License

No license is assigned. Add a license file if you want to grant others explicit permission to reuse or distribute this code.
