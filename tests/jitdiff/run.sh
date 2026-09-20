#!/bin/bash
# run.sh [pasriscv-src-dir]: builds JITDiff against PasRISCV.pas, assembles the tests, runs each
# with the JIT off and on (vecfp additionally with the strict FPU off and on) and compares all
# signatures with the pure interpreter run and, when qemu-system-riscv64 is installed, with QEMU.
#
# Environment: FPC (fpc), EXTDIR (<src>/../externals), WORK (<this dir>/out),
#              CROSS (riscv64-linux-gnu-), QEMU (qemu-system-riscv64, set empty to skip),
#              QEMU_PORT (45123, local TCP port for the QEMU monitor)
# Exit status is 0 when every comparison matches.
set -u
export LC_ALL=C
HERE=$(cd "$(dirname "$0")" && pwd)
SRC=$(cd "${1:-$HERE/../../src}" && pwd) || exit 1
EXTDIR=${EXTDIR:-$SRC/../externals}
FPC=${FPC:-fpc}
CROSS=${CROSS:-riscv64-linux-gnu-}
QEMU=${QEMU-qemu-system-riscv64}
QEMU_PORT=${QEMU_PORT:-45123}
WORK=${WORK:-$HERE/out}
MARCH=rv64gcv_zfh_zba_zbb_zbs_zbc_zbkb_zbkx_zknh_zksh_zkne_zknd_zksed_zicond_zcb_zvbb_zihintntl
FAILED=0

mkdir -p "$WORK/units" || exit 1

echo "== build JITDiff against $SRC/PasRISCV.pas"
if ! "$FPC" -Mdelphi -O2 -Fu"$SRC" -Fu"$EXTDIR/pasmp/src" -Fu"$EXTDIR/rnl/src" -Fu"$EXTDIR/pasterm/src" \
             -FU"$WORK/units" -FE"$WORK" "$HERE/JITDiff.dpr" > "$WORK/build.log" 2>&1; then
  tail -20 "$WORK/build.log"
  exit 1
fi

# assemble <source> <name>: <name>.elf/.bin for PasRISCV, <name>.qemu.elf without the SYSCON
# power off store (QEMU has no device there, the test just spins at the end instead)
assemble() {
  "${CROSS}gcc" -nostdlib -nostartfiles -march=$MARCH -mabi=lp64d -Wl,--build-id=none -Wl,-Ttext=0x80000000 \
   -o "$WORK/$2.elf" "$1" || return 1
  "${CROSS}objcopy" -O binary -j .text "$WORK/$2.elf" "$WORK/$2.bin" || return 1
  sed '/^  li t1, 0x5555$/{n;s/^  sw t1, 0(t0)$/  nop/}' "$1" > "$WORK/$2.qemu.S"
  "${CROSS}gcc" -nostdlib -nostartfiles -march=$MARCH -mabi=lp64d -Wl,--build-id=none -Wl,-Ttext=0x80000000 \
   -o "$WORK/$2.qemu.elf" "$WORK/$2.qemu.S"
}

# run <name> <jit> <strict>: writes <name>.j<jit>.s<strict>.txt
run() {
  timeout 300 "$WORK/JITDiff" "$WORK/$1.bin" "$2" "$3" > "$WORK/$1.j$2.s$3.txt" 2>&1 || {
    echo "  FAIL $1 jit=$2 strict=$3: JITDiff did not finish"
    FAILED=1
  }
}

# compare <label> <ref> <test> [<desc>]
compare() {
  if cmp -s "$2" "$3"; then
    echo "  ok   $1"
  else
    echo "  FAIL $1: $(diff <(tail -n +2 "$2") <(tail -n +2 "$3") | grep -c '^>') differing dwords"
    if [ $# -ge 4 ]; then
      "$HERE/cmp.sh" "$4" "$2" "$3" | head -20
    fi
    FAILED=1
  fi
}

# monitor <command...>: sends commands to the QEMU monitor
monitor() {
  exec 3<>"/dev/tcp/127.0.0.1/$QEMU_PORT" || return 1
  printf '%s\n' "$@" >&3
  sleep 1
  exec 3>&-
}

# qemu_run <name>: writes <name>.qemu.txt in the JITDiff output format
qemu_run() {
  local qpid n i
  rm -f "$WORK/$1.qcnt.bin" "$WORK/$1.qsig.bin"
  (cd "$WORK" && exec "$QEMU" -M virt -cpu max,vlen=256 -bios none -kernel "$1.qemu.elf" -m 64M \
    -display none -serial none -monitor "tcp:127.0.0.1:$QEMU_PORT,server,nowait" > "$1.qemu.log" 2>&1) &
  qpid=$!
  for i in $(seq 1 50); do
    (exec 3<>"/dev/tcp/127.0.0.1/$QEMU_PORT") 2>/dev/null && break
    sleep 0.2
  done
  n=0
  for i in $(seq 1 120); do
    monitor "pmemsave 0x807ffff8 8 $1.qcnt.bin"
    if [ -s "$WORK/$1.qcnt.bin" ]; then
      n=$(od -An -tu8 "$WORK/$1.qcnt.bin" | tr -d ' ')
      [ "$n" != "0" ] && break
    fi
  done
  if [ "$n" = "0" ]; then
    echo "  FAIL $1: QEMU did not finish"
    FAILED=1
  else
    monitor "pmemsave 0x80800000 $((n*8)) $1.qsig.bin"
    od -An -v -tx8 -w8 "$WORK/$1.qsig.bin" | tr -d ' ' | tr 'a-f' 'A-F' | sed "1i count $n" > "$WORK/$1.qemu.txt"
  fi
  monitor "quit"
  wait $qpid 2>/dev/null
}

HAVEQEMU=0
if [ -n "$QEMU" ] && command -v "$QEMU" > /dev/null 2>&1; then
  HAVEQEMU=1
fi

echo "== jitdiff: integer instructions the JIT translates, all register aliasing combinations"
bash "$HERE/gen.sh" "$WORK" || exit 1
assemble "$WORK/jitdiff.S" jitdiff || exit 1
run jitdiff 0 0
run jitdiff 1 0
compare "JIT against interpreter" "$WORK/jitdiff.j0.s0.txt" "$WORK/jitdiff.j1.s0.txt" "$WORK/desc.txt"
if [ $HAVEQEMU = 1 ]; then
  qemu_run jitdiff
  [ -f "$WORK/jitdiff.qemu.txt" ] && compare "interpreter against QEMU" "$WORK/jitdiff.qemu.txt" "$WORK/jitdiff.j0.s0.txt" "$WORK/desc.txt"
fi

echo "== vsetvli_alias: JIT vsetvli and slli.uw with rd == rs1"
assemble "$HERE/vsetvli_alias.S" vsetvli_alias || exit 1
run vsetvli_alias 0 0
run vsetvli_alias 1 0
compare "JIT against interpreter" "$WORK/vsetvli_alias.j0.s0.txt" "$WORK/vsetvli_alias.j1.s0.txt"
if [ $HAVEQEMU = 1 ]; then
  qemu_run vsetvli_alias
  [ -f "$WORK/vsetvli_alias.qemu.txt" ] && compare "interpreter against QEMU" "$WORK/vsetvli_alias.qemu.txt" "$WORK/vsetvli_alias.j0.s0.txt"
fi

echo "== vecfp: vector and floating point checks"
assemble "$HERE/vecfp.S" vecfp || exit 1
for s in 0 1; do
  for j in 0 1; do
    run vecfp $j $s
  done
done
if [ "$(tail -3 "$WORK/vecfp.j0.s0.txt" | tr -d '0\n')" != "" ]; then
  echo "  FAIL traps in the interpreter run (count, mcause, mepc): $(tail -3 "$WORK/vecfp.j0.s0.txt" | tr '\n' ' ')"
  FAILED=1
else
  echo "  ok   no traps"
fi
compare "JIT against interpreter" "$WORK/vecfp.j0.s0.txt" "$WORK/vecfp.j1.s0.txt"
compare "strict FPU against fast FPU" "$WORK/vecfp.j0.s0.txt" "$WORK/vecfp.j0.s1.txt"
compare "strict FPU with JIT against interpreter" "$WORK/vecfp.j0.s0.txt" "$WORK/vecfp.j1.s1.txt"
if [ $HAVEQEMU = 1 ]; then
  qemu_run vecfp
  [ -f "$WORK/vecfp.qemu.txt" ] && compare "interpreter against QEMU" "$WORK/vecfp.qemu.txt" "$WORK/vecfp.j0.s0.txt"
else
  echo "== $QEMU not found, QEMU comparisons skipped"
fi

echo "== pressure: flh/fsh and static rounding modes under host register pressure"
bash "$HERE/gen_pressure.sh" "$WORK" || exit 1
assemble "$WORK/pressure.S" pressure || exit 1
run pressure 0 0
run pressure 1 0
compare "JIT against interpreter" "$WORK/pressure.j0.s0.txt" "$WORK/pressure.j1.s0.txt"
if [ $HAVEQEMU = 1 ]; then
  qemu_run pressure
  [ -f "$WORK/pressure.qemu.txt" ] && compare "interpreter against QEMU" "$WORK/pressure.qemu.txt" "$WORK/pressure.j0.s0.txt"
fi

echo "== nofeatures: JIT on a host without LZCNT, BMI1, POPCNT and F16C (those intrinsics decline)"
for t in jitdiff pressure vecfp; do
  timeout 300 "$WORK/JITDiff" "$WORK/$t.bin" 1 0 nofeatures > "$WORK/$t.j1.s0.nf.txt" 2>&1 || {
    echo "  FAIL $t nofeatures: JITDiff did not finish"
    FAILED=1
  }
  compare "$t: JIT without the features against interpreter" "$WORK/$t.j0.s0.txt" "$WORK/$t.j1.s0.nf.txt"
done
if [ $FAILED = 0 ]; then
  echo "== all comparisons match"
else
  echo "== FAILED"
fi
exit $FAILED
