#!/bin/bash
# gen.sh [outdir]: writes jitdiff.S and desc.txt to outdir (default: current directory).
# jitdiff.S is a bare-metal test that runs every integer instruction the JIT translates,
# in all register aliasing combinations (rd=rs1, rd=rs2, rs1=rs2, all equal) and with
# several value sets. The body runs PASSES times; every test stores a0..a3 to the
# signature area, so pass 0 (interpreted while tracing) can be compared with the later
# passes (JIT code), with a run where the JIT is disabled and with QEMU.
# desc.txt has one line per test and pass, used by cmp.sh to name mismatches.
export LC_ALL=C
OUT=${1:-.}
PASSES=4
SIG=0x80800000
CNT=0x807ffff8

RR="add sub sll slt sltu xor srl sra or and addw subw sllw srlw sraw
mul mulh mulhsu mulhu div divu rem remu mulw divw divuw remw remuw
sh1add sh2add sh3add add.uw sh1add.uw sh2add.uw sh3add.uw
andn orn xnor max maxu min minu rol ror rolw rorw
bclr bext binv bset clmul clmulh clmulr
pack packh packw xperm4 xperm8 czero.eqz czero.nez
aes64es aes64esm aes64ds aes64dsm aes64ks2"
RRBS="sm4ed sm4ks"
UN="clz ctz cpop clzw ctzw cpopw sext.b sext.h zext.h zext.w orc.b rev8 brev8
sha256sum0 sha256sum1 sha256sig0 sha256sig1 sha512sum0 sha512sum1 sha512sig0 sha512sig1
sm3p0 sm3p1 aes64im"
IMMA="addi slti sltiu xori ori andi addiw"
IMMA_V="0 1 -1 2047 -2048 1365"
SH64="slli srli srai slli.uw rori bclri bexti binvi bseti"
SH64_V="0 1 31 32 63"
SH32="slliw srliw sraiw roriw"
SH32_V="0 1 31"
CUN="c.zext.b c.sext.b c.zext.h c.sext.h c.zext.w c.not"
CRR="c.mul c.addw c.subw c.and c.or c.xor c.sub c.add"
CIMM="c.slli:5 c.slli:33 c.srli:1 c.srli:33 c.srai:1 c.srai:63 c.andi:-7 c.andi:31 c.addiw:-3 c.addiw:0 c.addi:9"

# value sets: a1 a2
VALS="0xfedcba9887654321:0x0123456789abcdef
0x7fffffff80000000:0xffffffff000000e5
0xffffffffffffffff:0x8000000000000000
0x0000000123456789:0x0000000000000000
0x00000000ffffffff:0x000000000000003f"

T=0
emit_set() { # $1=a1 $2=a2
  echo "  li a0, 0xa5a5a5a5a5a5a5a5"
  echo "  li a1, $1"
  echo "  li a2, $2"
  echo "  li a3, 0x5a5a5a5a5a5a5a5a"
}
emit_store() {
  echo "  sd a0, 0(s0)"
  echo "  sd a1, 8(s0)"
  echo "  sd a2, 16(s0)"
  echo "  sd a3, 24(s0)"
  echo "  addi s0, s0, 32"
  T=$((T+1))
}
test_insn() { # $1 = instruction text
  local v a b
  for v in $VALS; do
    a=${v%%:*}; b=${v##*:}
    emit_set $a $b
    echo "  $1"; echo "$1 | a1=$a a2=$b" >&3
    emit_store
  done
}

{
echo "  .option push"; echo "  .option norvc"
echo "  .globl _start"
echo "_start:"
echo "  li s1, $PASSES"
echo "  li s0, $SIG"
# The loop starts on a fresh page: after a TLB flush the JIT only finds blocks again
# once the interpreter refetches through the TLB
echo "  j pass_loop"
echo "  .align 12"
echo "pass_loop:"
for i in $RR; do
  for f in "a0, a1, a2" "a1, a1, a2" "a2, a1, a2" "a0, a1, a1" "a1, a1, a1"; do
    test_insn "$i $f"
  done
done
for i in $RRBS; do
  for bs in 0 3; do
    for f in "a0, a1, a2" "a1, a1, a2" "a2, a1, a2" "a0, a1, a1" "a1, a1, a1"; do
      test_insn "$i $f, $bs"
    done
  done
done
for i in $UN; do
  for f in "a0, a1" "a1, a1"; do
    test_insn "$i $f"
  done
done
for i in $IMMA; do
  for im in $IMMA_V; do
    for f in "a0, a1" "a1, a1"; do
      test_insn "$i $f, $im"
    done
  done
done
for i in $SH64; do
  for im in $SH64_V; do
    for f in "a0, a1" "a1, a1"; do
      test_insn "$i $f, $im"
    done
  done
done
for i in $SH32; do
  for im in $SH32_V; do
    for f in "a0, a1" "a1, a1"; do
      test_insn "$i $f, $im"
    done
  done
done
for rn in 0 5 10; do
  for f in "a0, a1" "a1, a1"; do
    test_insn "aes64ks1i $f, $rn"
  done
done
echo "  .option pop"
for i in $CUN; do
  test_insn "$i a1"
done
for i in $CRR; do
  for f in "a0, a1" "a1, a1"; do
    test_insn "$i $f"
  done
done
for c in $CIMM; do
  test_insn "${c%%:*} a1, ${c##*:}"
done
echo "  .option push"; echo "  .option norvc"
echo "  addi s1, s1, -1"
echo "  beqz s1, finish"
echo "  j pass_loop"
echo "finish:"
echo "  li t0, $SIG"
echo "  sub t1, s0, t0"
echo "  srli t1, t1, 3"
echo "  li t0, $CNT"
echo "  sd t1, 0(t0)"
echo "  li t0, 0x11100000"
echo "  li t1, 0x5555"
echo "  sw t1, 0(t0)"
echo "1: j 1b"
} > "$OUT/jitdiff.S" 3> "$OUT/desc.txt"
echo "gen.sh: $T tests per pass" >&2
