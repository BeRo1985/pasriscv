# A locked entry ignores later pmpaddr and pmpcfg writes (from the external audit)
# expect: s0=0000000000000093 s1=0000000020001000 s2=0000000000000000 cause=0000000000000000
#include "head.inc"
  csrr s2,mseccfg
  li t0, 0x20001000
  csrw pmpaddr0,t0
  li t1,0x93
  csrw pmpcfg0,t1
  sfence.vma
  addi t0,t0,4
  csrw pmpaddr0,t0
  csrw pmpcfg0,zero
  csrr s0,pmpcfg0
  csrr s1,pmpaddr0
#include "tail.inc"
