# pmpaddr bits 63:54, reserved pmpcfg bits, R=0 W=1 legalization, pmpcfg1 on RV64
# expect: s0=003FFFFFFFFFFFFF s1=0000000000001800 s2=000000003A1022F3 cause=0000000000000002
#include "head.inc"
  li t0, -1
  csrw pmpaddr1, t0
  csrr s0, pmpaddr1       # bits 63:54 read-only zero: expect 0x003fffffffffffff
  li t0, 0x7f00
  csrw pmpcfg0, t0        # entry 1: reserved bits 6:5 dropped -> 0x1f
  li t0, 0x1a00
  csrw pmpcfg0, t0        # entry 1: R=0 W=1 without MML, W is cleared
  csrr s1, pmpcfg0        # expect 0x1800 (W cleared)
  csrr t0, pmpcfg1        # RV64: illegal instruction, cause 2
#include "tail.inc"
