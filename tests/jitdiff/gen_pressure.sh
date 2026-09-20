#!/bin/bash
# gen_pressure.sh <outdir>: writes <outdir>/pressure.S, a JIT check under host register pressure
# Block k first writes k guest registers, so that the JIT
# has mapped k host registers, and then does flh/fsh with offset 0 and a nonzero offset (the
# address register ends up in RBX, RBP, R12, R13 and so on) and FP operations with a static
# rounding mode whose code claims integer registers inside the MXCSR window. Each block ends with
# a jump, so that the next one starts with fresh mappings. The body runs four times: the first
# pass is interpreted while the JIT traces, the later ones run the translated blocks.
set -u
OUT=${1:-.}
REGS=(ra sp gp tp t0 t1 t2 a1 a2 a3 a4 a5 a6 a7 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 t3 t4 t5 t6)
{
  echo "  .option norvc"
  echo "  .globl _start"
  echo "_start:"
  echo "  li t0, 0x2000"
  echo "  csrs mstatus, t0            # FS=Initial"
  echo "  li t0, 0x80700000            # 64 halfwords of source data"
  echo "  li t1, 0x3c00"
  echo "  li t2, 64"
  echo "1:"
  echo "  sh t1, 0(t0)"
  echo "  addi t1, t1, 17"
  echo "  addi t0, t0, 2"
  echo "  addi t2, t2, -1"
  echo "  bnez t2, 1b"
  echo "  li s0, 0x80800000            # signature"
  echo "  li s1, 4                     # passes"
  echo "  j pass"
  echo "  .align 12"
  echo "pass:"
  echo "  li a0, 0x80700000"
  for ((k=0;k<=${#REGS[@]};k++)); do
    echo "blk$k:"
    for ((i=0;i<k;i++)); do
      echo "  li ${REGS[$i]}, $((i+1))"
    done
    OFF=$(( (k*2+2) % 120 ))
    echo "  flh f1, 0(a0)"
    echo "  fsh f1, 0(s0)"
    echo "  flh f2, $OFF(a0)"
    echo "  fsh f2, 2(s0)"
    if [ $k -gt 0 ]; then
      echo "  fcvt.d.lu f3, ${REGS[$((k-1))]}, rup"
      echo "  fcvt.s.l f4, ${REGS[$((k-1))]}, rdn"
      echo "  fcvt.lu.d ${REGS[$((k-1))]}, f3, rtz"
      echo "  sd ${REGS[$((k-1))]}, 16(s0)"
    else
      echo "  fcvt.d.lu f3, s1, rup"
      echo "  fcvt.s.l f4, s1, rdn"
    fi
    echo "  fadd.d f5, f3, f3, rdn"
    echo "  fsd f5, 8(s0)"
    echo "  fsw f4, 4(s0)"
    echo "  addi s0, s0, 24"
    echo "  j blk$((k+1))"
  done
  echo "blk$(( ${#REGS[@]} + 1 )):"
  echo "  addi s1, s1, -1"
  echo "  bnez s1, pass"
  echo "  li t0, 0x80800000"
  echo "  sub t1, s0, t0"
  echo "  srli t1, t1, 3"
  echo "  li t0, 0x807ffff8"
  echo "  sd t1, 0(t0)"
  echo "  li t0, 0x11100000"
  echo "  li t1, 0x5555"
  echo "  sw t1, 0(t0)"
  echo "1: j 1b"
} > "$OUT/pressure.S"
