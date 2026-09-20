#!/bin/sh
# Cross-compile cryptotest.c to riscv64 using clang
set -e

MARCH="rv64gcv_zbkb_zbkc_zbkx_zknd_zkne_zknh_zksed_zksh_zkr_zvbb_zvbc_zvkg_zvkned_zvknha_zvknhb_zvksed_zvksh"

clang \
  --target=riscv64-linux-gnu \
  --sysroot=/usr/riscv64-linux-gnu \
  -march="$MARCH" \
  -mabi=lp64d \
  -O2 \
  -static \
  -o cryptotest \
  cryptotest.c

echo "Built: cryptotest (riscv64-linux-gnu, static)"

file cryptotest
