  .option norvc
  .globl _start
_start:
  lla t0, trap
  csrw mtvec, t0
  li s0, 0
  li s1, 0
  li s2, 0
  li s4, 0
