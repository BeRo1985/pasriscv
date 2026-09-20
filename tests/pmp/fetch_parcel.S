# The second parcel of a 32-bit instruction beyond a PMP execute boundary faults
# expect: s0=0000000000000000 s1=0000000000000000 s2=0000000080000078 cause=0000000000000001
#include "head.inc"
  # entry 0: TOR [0, boundary) R+X, entry 1: everything else R+W only (for S-mode)
  lla t0, boundary
  srli t0, t0, 2
  csrw pmpaddr0, t0
  li t0, -1
  csrw pmpaddr1, t0
  li t0, 0x1b0d
  csrw pmpcfg0, t0
  li t0, 0x1800
  csrc mstatus, t0
  li t0, 0x0800
  csrs mstatus, t0            # MPP=S
  lla t0, s_code
  csrw mepc, t0
  mret
  .align 4
s_code:
  nop
  .option rvc
  c.nop
  .option norvc
  li s0, 1                    # 32-bit instruction whose second parcel lies beyond the boundary
  .equ boundary, s_code+8
  j done
  .align 8
trap:
  csrr s4, mcause
  csrr s2, mtval
done:
  li s11, 0x1234
1: j 1b
