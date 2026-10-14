#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
iverilog -g2012 -Wall -s spi_tb -o build/spi_sim \
  rtl/spi_master.sv rtl/spi_slave.sv rtl/spi_top.sv tb/spi_tb.sv
vvp build/spi_sim
