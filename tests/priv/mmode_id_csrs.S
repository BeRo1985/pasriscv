# misa, mvendorid, marchid, mimpid, mhartid and tdata1 are M-level CSRs: from S- and U-mode
# every access raises an illegal-instruction exception (2), also a write to misa from S-mode,
# which the old handler ignored silently. M-mode reads them, and a write to the WARL misa keeps
# its value.
# expect: s1=0000000000000000 a0=0000000002020202 a1=0000000000020202 a2=0000000000000202
#include "head.inc"
  csrr s0, misa
  csrw misa, zero
  csrr s1, misa
  sub s1, s1, s0
  ENTER_HS s_mode
s_mode:
  PROBE8 a0, csrr t0, misa
  PROBE8 a0, csrr t0, mvendorid
  PROBE8 a0, csrr t0, marchid
  PROBE8 a0, csrr t0, mimpid
  PROBE8 a1, csrr t0, mhartid
  PROBE8 a1, csrr t0, tdata1
  PROBE8 a1, csrw misa, zero
  SRET_U u_mode
u_mode:
  PROBE8 a2, csrr t0, mhartid
  PROBE8 a2, csrr t0, misa
  TO_M m_end
m_end:
  j done
#include "tail.inc"
