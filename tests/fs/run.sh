#!/bin/bash
# run.sh [pasriscv-src-dir]: builds FSProbe against PasRISCV.pas, prepares a directory with a
# regular file, a symbolic link and a subdirectory, and checks what the 9P file system reports for
# them: the qid type of each entry (a regular file must not look like a symbolic link), a qid path
# that is not the bare inode number and differs per entry, and the error codes of a name that is
# too long (ENAMETOOLONG) and of opening a fifo for writing without a reader (ENXIO), both of
# which used to come out as EINVAL.
#
# Environment: FPC (fpc), EXTDIR (<src>/../externals), WORK (<this dir>/out)
# Exit status is 0 when every check matches.
set -u
export LC_ALL=C
HERE=$(cd "$(dirname "$0")" && pwd)
SRC=$(cd "${1:-$HERE/../../src}" && pwd) || exit 1
EXTDIR=${EXTDIR:-$SRC/../externals}
FPC=${FPC:-fpc}
WORK=${WORK:-$HERE/out}
FAILED=0

mkdir -p "$WORK/units" "$WORK/share/dir" || exit 1

echo "== build FSProbe against $SRC/PasRISCV.pas"
if ! "$FPC" -Mdelphi -O2 -Fu"$SRC" -Fu"$EXTDIR/pasmp/src" -Fu"$EXTDIR/rnl/src" -Fu"$EXTDIR/pasterm/src" \
            -FU"$WORK/units" -FE"$WORK" "$HERE/FSProbe.dpr" > "$WORK/build.log" 2>&1; then
  tail -20 "$WORK/build.log"
  exit 1
fi

echo "content" > "$WORK/share/reg"
ln -sf reg "$WORK/share/lnk"
rm -f "$WORK/share/fifo"
mkfifo "$WORK/share/fifo"

GOT=$("$WORK/FSProbe" "$WORK/share")
echo "$GOT"

check() {
  if ! echo "$GOT" | grep -q "^$1\$"; then
    echo "  FAIL: expected \"$1\""
    FAILED=1
  fi
}

# P9_QTFILE=0, P9_QTSYMLINK=2, P9_QTDIR=0x80=128
check "qidtype reg=0 lnk=2 dir=128"
check "qidpath ino=0 uniq=1"
# ENAMETOOLONG=36, ENXIO=6
check "errno long=36 fifo=6"

if [ $FAILED -eq 0 ]; then
  echo "== all file system checks match"
else
  echo "== FAILED"
fi
exit $FAILED
