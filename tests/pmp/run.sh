#!/bin/bash
# run.sh [pasriscv-src-dir]: builds PMPProbe against PasRISCV.pas, assembles every test *.S and
# compares s0, s1, s2 and the trap cause with the "# expect:" line of the test.
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
FAILED=0

mkdir -p "$WORK/units" || exit 1

echo "== build PMPProbe against $SRC/PasRISCV.pas"
if ! "$FPC" -Mdelphi -O2 -Fu"$SRC" -Fu"$EXTDIR/pasmp/src" -Fu"$EXTDIR/rnl/src" -Fu"$EXTDIR/pasterm/src" \
             -FU"$WORK/units" -FE"$WORK" "$HERE/PMPProbe.dpr" > "$WORK/build.log" 2>&1; then
  tail -20 "$WORK/build.log"
  exit 1
fi

for S in "$HERE"/*.S; do
  NAME=$(basename "$S" .S)
  EXPECT=$(sed -n 's/^# expect: //p' "$S")
  if ! "${CROSS}gcc" -nostdlib -nostartfiles -march=rv64gc -mabi=lp64d -Wl,--build-id=none -Wl,-Ttext=0x80000000 \
       -I"$HERE" -o "$WORK/$NAME.elf" "$S" > "$WORK/$NAME.as.log" 2>&1 ||
     ! "${CROSS}objcopy" -O binary -j .text "$WORK/$NAME.elf" "$WORK/$NAME.bin"; then
    echo "  FAIL $NAME: does not assemble, see $WORK/$NAME.as.log"
    FAILED=1
    continue
  fi
  GOT=$(timeout 30 "$WORK/PMPProbe" "$WORK/$NAME.bin")
  RC=$?
  if [ $RC -ne 0 ]; then
    echo "  FAIL $NAME: end marker not reached ($GOT)"
    FAILED=1
  elif [ "$GOT" = "$EXPECT" ]; then
    echo "  ok   $NAME"
  else
    echo "  FAIL $NAME"
    echo "       expected $EXPECT"
    echo "       got      $GOT"
    FAILED=1
  fi
done

if [ $FAILED = 0 ]; then
  echo "== all PMP tests match"
else
  echo "== FAILED"
fi
exit $FAILED
