# MML and MMWP are sticky, RLB can not be set while an entry is locked
# expect: s0=0000000000000003 s1=0000000000000003 s2=0000000000000000 cause=0000000000000000
#include "head.inc"
  # entry 0: locked, M-mode R+X on everything, so code keeps running with MML=1
  li t0, -1
  csrw pmpaddr0, t0
  li t0, 0x9d
  csrw pmpcfg0, t0
  li t0, 1
  csrs 0x747, t0
  li t0, 2
  csrs 0x747, t0
  li t0, 3
  csrc 0x747, t0
  csrr s0, 0x747          # MML and MMWP are sticky: expect 3
  li t0, 4
  csrs 0x747, t0
  csrr s1, 0x747          # RLB can not be set with a locked entry: expect 3
#include "tail.inc"
