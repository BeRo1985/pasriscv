#!/bin/bash
# cmp.sh <desc.txt> <ref.txt> <test.txt>: compares two jitdiff signatures (output of JITDiff or
# converted QEMU memory dumps) and prints every differing register with the test description.
# Signature layout: header line "count N", then passes x tests x 4 dwords (a0 a1 a2 a3).
awk 'FILENAME==ARGV[1] {desc[FNR-1]=$0; nt=FNR; next}
  FNR==1 {next}
  FILENAME==ARGV[2] {ref[FNR-2]=$1; next}
  { i=FNR-2; if (ref[i]!=$1) { pass=int(i/(nt*4)); t=int((i%(nt*4))/4); r=i%4;
    printf "pass %d test %d a%d: %s  ref=%s got=%s\n", pass, t, r, desc[t], ref[i], $1 } }' "$1" "$2" "$3"
