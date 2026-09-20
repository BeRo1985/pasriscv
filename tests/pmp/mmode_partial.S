# A partial match fails in M-mode too
# expect: s0=0000000000000000 s1=0000000000000000 s2=0000000080006000 cause=0000000000000005
#include "head.inc"
  li t0, 0x80006000
  srli t1, t0, 2
  csrw pmpaddr0, t1
  li t1, 0x13                 # entry 0: NA4 R+W, not locked
  csrw pmpcfg0, t1
  ld s0, 0(t0)                # M-mode, 8 bytes, only 4 inside entry 0: expect load access fault (5)
#include "tail.inc"
