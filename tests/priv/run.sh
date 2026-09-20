#!/bin/bash
# run.sh [pasriscv-src-dir]: builds PrivProbe against PasRISCV.pas, assembles every test *.S, runs
# it in the interpreter (single step) and with the JIT (Machine.Run), and checks the registers
# named in the "# expect:" line of the test (a subset of s0 to s10 and a0 to a7, as 16 uppercase
# hex digits) in both runs.
#
# Environment: FPC (fpc), EXTDIR (<src>/../externals), WORK (<this dir>/out),
#              CROSS (riscv64-linux-gnu-)
# Exit status is 0 when every test matches.
set -u
export LC_ALL=C
HERE=$(cd "$(dirname "$0")" && pwd)
SRC=$(cd "${1:-$HERE/../../src}" && pwd) || exit 1
EXTDIR=${EXTDIR:-$SRC/../externals}
FPC=${FPC:-fpc}
CROSS=${CROSS:-riscv64-linux-gnu-}
WORK=${WORK:-$HERE/out}
MARCH=rv64gch_svinval_zicfiss_zicfilp_zimop_zcmop
FAILED=0

mkdir -p "$WORK/units" || exit 1

echo "== build PrivProbe against $SRC/PasRISCV.pas"
if ! "$FPC" -Mdelphi -O2 -Fu"$SRC" -Fu"$EXTDIR/pasmp/src" -Fu"$EXTDIR/rnl/src" -Fu"$EXTDIR/pasterm/src" \
             -FU"$WORK/units" -FE"$WORK" "$HERE/PrivProbe.dpr" > "$WORK/build.log" 2>&1; then
  tail -20 "$WORK/build.log"
  exit 1
fi

for S in "$HERE"/*.S; do
  NAME=$(basename "$S" .S)
  EXPECT=$(sed -n 's/^# expect: //p' "$S")
  if ! "${CROSS}gcc" -nostdlib -nostartfiles -march=$MARCH -mabi=lp64d -Wl,--build-id=none -Wl,-Ttext=0x80000000 \
       -I"$HERE" -I"$HERE/../hext" -o "$WORK/$NAME.elf" "$S" > "$WORK/$NAME.as.log" 2>&1 ||
     ! "${CROSS}objcopy" -O binary -j .text "$WORK/$NAME.elf" "$WORK/$NAME.bin"; then
    echo "  FAIL $NAME: does not assemble, see $WORK/$NAME.as.log"
    FAILED=1
    continue
  fi
  for MODE in step jit; do
    GOT=$(timeout 30 "$WORK/PrivProbe" "$WORK/$NAME.bin" $MODE)
    RC=$?
    if [ $RC -ne 0 ]; then
      echo "  FAIL $NAME ($MODE): end marker not reached ($GOT)"
      FAILED=1
      continue
    fi
    MISMATCH=""
    for TOKEN in $EXPECT; do
      case " $GOT " in
        *" $TOKEN "*) ;;
        *) MISMATCH="$MISMATCH $TOKEN" ;;
      esac
    done
    if [ -z "$MISMATCH" ]; then
      echo "  ok   $NAME ($MODE)"
    else
      echo "  FAIL $NAME ($MODE)"
      echo "       expected$MISMATCH"
      echo "       got      $GOT"
      FAILED=1
    fi
  done
done

if [ $FAILED = 0 ]; then
  echo "== all privilege tests match"
else
  echo "== FAILED"
fi
exit $FAILED
