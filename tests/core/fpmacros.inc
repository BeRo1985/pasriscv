# Check macros for the FP tests: a0 counts the passed checks, a1 collects bit n of every failed
# check (n = the bit argument, 0 to 62). The expected value is a 64-bit constant. fmv.x.w and
# fmv.x.h sign-extend, so a single or half is expected as its sign-extended bits. Uses t4, t5.
.macro CHKX reg, val, bit
  li t5, \val
  bne \reg, t5, 91f
  addi a0, a0, 1
  j 92f
91:
  li t5, 1 << \bit
  or a1, a1, t5
92:
.endm

.macro CHKS freg, val, bit
  fmv.x.w t4, \freg
  CHKX t4, \val, \bit
.endm

.macro CHKD freg, val, bit
  fmv.x.d t4, \freg
  CHKX t4, \val, \bit
.endm

.macro CHKH freg, val, bit
  fmv.x.h t4, \freg
  CHKX t4, \val, \bit
.endm

# fflags equal val, then cleared
.macro CHKFLAGS val, bit
  frflags t4
  fsflags zero
  CHKX t4, \val, \bit
.endm

# Load raw bits into an FP register
.macro FLIS freg, val
  li t4, \val
  fmv.w.x \freg, t4
.endm

.macro FLID freg, val
  li t4, \val
  fmv.d.x \freg, t4
.endm

.macro FLIH freg, val
  li t4, \val
  fmv.h.x \freg, t4
.endm

# A half NaN, sign and payload free: the interpreter gives the canonical 0x7e00, the JIT only
# with PasRISCVJITCanonicalHalfNaN, otherwise what vcvtps2ph gives (inf-inf becomes 0xfe00).
# fclass bit 8 is a signaling, bit 9 a quiet NaN.
.macro CHKHNAN freg, bit
  fclass.h t4, \freg
  andi t4, t4, 0x300
  snez t4, t4
  CHKX t4, 1, \bit
.endm
