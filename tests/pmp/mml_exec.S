# With MML=1, M-mode can not execute code without a matching rule
# expect: s0=0000000000000000 s1=0000000000000000 s2=0000000080000040 cause=0000000000000001
#include "head.inc"
  # entry 0: 256-byte NAPOT on the trap handler, locked M-mode R+X
  lla t0, trap
  srli t0, t0, 2
  ori t0, t0, 0x1f
  csrw pmpaddr0, t0
  li t0, 0x9d
  csrw pmpcfg0, t0
  li t0, 1
  csrs 0x747, t0          # MML=1: this code has no matching rule any more
  li s0, 1                # expect instruction access fault here (cause 1), s0 stays 0
#include "tail.inc"
