# With FS=Off, c.fld and c.fsd (like fld) and the fcsr, fflags and frm CSRs raise an
# illegal-instruction exception (2) and leave FS alone (the old c.fld/c.fsd and CSR handlers ran
# and set FS to Dirty). With FS=Initial they work and c.fld sets FS to Dirty. With V=1 the
# vsstatus.FS=Off of the guest disables them as well.
# expect: a0=0000000002020202 a1=0000000000020202 a2=0000000000000000 a3=0000000000000000 s0=0000000000000003 a5=4000000000000000 a6=0000000000001111 a7=0000000000000202
#include "head.inc"
  GSTAGE_IDENTITY
  lla a4, fpdata
  li t0, 0x6000
  csrc mstatus, t0
  .option push
  .option rvc
  PROBE8 a0, c.fld fa0, 0(a4)
  PROBE8 a0, c.fsd fa0, 8(a4)
  PROBE8 a0, fld fa0, 0(a4)
  PROBE8 a0, csrr t0, fcsr
  PROBE8 a1, csrw fflags, zero
  PROBE8 a1, frrm t0
  PROBE8 a1, fsrmi 1
  .option pop
  csrr t0, mstatus
  srli t0, t0, 13
  andi a2, t0, 3
  ld a6, 8(a4)
  # FS=Initial
  li t0, 0x2000
  csrs mstatus, t0
  .option push
  .option rvc
  PROBE8 a3, c.fld fa0, 0(a4)
  PROBE8 a3, csrr t0, fcsr
  .option pop
  fmv.x.d a5, fa0
  csrr t0, mstatus
  srli t0, t0, 13
  andi s0, t0, 3
  # VS-mode with vsstatus.FS=Off (mstatus.FS is Dirty)
  li t0, 0x6000
  csrc vsstatus, t0
  ENTER_VS vs1
vs1:
  .option push
  .option rvc
  PROBE8 a7, c.fld fa0, 0(a4)
  PROBE8 a7, csrr t0, fcsr
  .option pop
  TO_M m1
m1:
  j done
  .align 3
fpdata:
  .dword 0x4000000000000000
  .dword 0x1111
#include "tail.inc"
