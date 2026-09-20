# fround/froundnx in the fast path rounded with Math.Floor/Math.Ceil, which return a 32-bit
# Integer, so RDN/RUP broke from 2^31 on. 11 checks per round, 20 rounds for the JIT.
# expect: a0=00000000000000DC a1=0000000000000000
#include "head.inc"
#include "fpmacros.inc"
  li t0, 0x2000
  csrs mstatus, t0
  li s9, 20
  jal t2, froundloop
  j done

  .balign 4096
froundloop:
1:
  fsrmi 0
  FLID ft0, 0x41e65a0bc0100000              # 3e9+0.5
  fround.d ft1, ft0, rdn
  CHKD ft1, 0x41e65a0bc0000000, 0
  fround.d ft1, ft0, rup
  CHKD ft1, 0x41e65a0bc0200000, 1
  FLID ft2, 0xc1e65a0bc0100000              # -3e9-0.5
  fround.d ft1, ft2, rdn
  CHKD ft1, 0xc1e65a0bc0200000, 2
  fround.d ft1, ft2, rup
  CHKD ft1, 0xc1e65a0bc0000000, 3
  FLID ft3, 0x430c6bf526340002              # 1e15+0.25
  froundnx.d ft1, ft3, rdn
  CHKD ft1, 0x430c6bf526340000, 4
  froundnx.d ft1, ft3, rup
  CHKD ft1, 0x430c6bf526340008, 5
  FLIS ft4, 0x4f32d05e                      # 3e9 single, already integral
  fround.s ft1, ft4, rdn
  CHKS ft1, 0x4f32d05e, 6
  FLIS ft5, 0xcf32d05e                      # -3e9
  fround.s ft1, ft5, rup
  CHKS ft1, 0xffffffffcf32d05e, 7
  FLIS ft6, 0x501502f9                      # 1e10
  froundnx.s ft1, ft6, rdn
  CHKS ft1, 0x501502f9, 8
  FLIS ft7, 0xd01502f9                      # -1e10
  fround.s ft1, ft7, rdn
  CHKS ft1, 0xffffffffd01502f9, 9
  fsrmi 2                                   # frm = RDN, dynamic
  fround.d ft1, ft0
  CHKD ft1, 0x41e65a0bc0000000, 10
  fsrmi 0
  addi s9, s9, -1
  bnez s9, 1b
  jr t2
#include "tail.inc"
