#!/bin/bash
# Builds the Svrsw60t59b page table bit test as a raw image for PasRISCVTest.
set -e

CC=${CC:-riscv64-elf-gcc}
OBJCOPY=${OBJCOPY:-riscv64-elf-objcopy}

cd "$(dirname "$0")"

$CC -march=rv64ima_zicsr_zifencei -mabi=lp64 -nostdlib -nostartfiles -Wl,--build-id=none \
    -T link.ld -o svrsw60t59b.elf svrsw60t59b.S

$OBJCOPY -O binary svrsw60t59b.elf svrsw60t59b.bin

echo "built svrsw60t59b.bin ($(stat -c %s svrsw60t59b.bin) bytes)"
