# With V=1 the time CSR reads time + htimedelta
# expect: a0=0000000000000010
#include "head.inc"
  li t0, -1
  csrw mcounteren, t0
  csrw hcounteren, t0
  li t0, 0x1000000000
  csrw htimedelta, t0
  GSTAGE_IDENTITY
  rdtime s7
  ENTER_VS guest
guest:
  rdtime t0
  sub t0, t0, s7
  srli a0, t0, 32
  j done
#include "tail.inc"
