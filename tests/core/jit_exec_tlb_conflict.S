# The TLB is direct mapped with one slot for all access types, so a load from a data page with
# the same index as the code page takes the execute entry of the code. When the translated loop
# then came back to the dispatcher (here after 100 rounds, in Linux at an interrupt), the
# dispatcher found no execute entry and the interpreter ran the page from its cached fetch pointer
# until the next trap or page change, about 20 times slower. The test times the same loop with the
# data page in another slot and in the slot of the code page (rdtime, 1 MHz) and expects the second
# run to take at most 4 times as long plus 2 ms. Only with the JIT (the single step run would be
# far too long).
# jitonly
# expect: a0=0000000000000001 a1=0000000000000000
#include "head.inc"
  # data page in another slot: code page + 1 MiB + 4 KiB
  lla a4, loop
  li t0, ~0xfff
  and a4, a4, t0
  li t0, 0x101000
  add a0, a4, t0
  li a1, 0
  li s7, 20000
  rdtime s0
  jal t2, loop
  rdtime t0
  sub s0, t0, s0
  mv a5, a1
  # data page in the slot of the code page: code page + 1 MiB (VPN differs by 256)
  li t0, 0x100000
  add a0, a4, t0
  li a1, 0
  li s7, 20000
  rdtime s1
  jal t2, loop
  rdtime t0
  sub s1, t0, s1
  # Both runs compute the same
  sub a1, a1, a5
  # a0 = conflict time < 4 * other time + 2000 us
  slli t0, s0, 2
  li t1, 2000
  add t0, t0, t1
  sltu a0, s1, t0
  mv a2, s0
  mv a3, s1
  j done

  .balign 4096
loop:
  li s9, 100
1:
  ld t0, 0(a0)
  add a1, a1, t0
  addi a1, a1, 1
  xor a1, a1, s9
  addi s9, s9, -1
  bnez s9, 1b
  # Not translated by the JIT: back to the dispatcher once per outer round
  csrr t1, mscratch
  addi s7, s7, -1
  bnez s7, loop
  jr t2
#include "tail.inc"
