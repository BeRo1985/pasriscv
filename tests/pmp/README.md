# PMP and page table walk tests

Bare-metal regression tests for PMP and the page table walk. The `pmp_*` and `pte_*` tests come
from the external audit (`/tmp/pasriscv-audit`), converted to `lla` so that they work as flat
binaries, the other tests cover the remaining points.

Each test runs in M-mode, sets up PMP (and page tables where needed), usually switches to S-mode
data accesses through `mstatus.MPRV`, and ends at the `done` label with `s11=0x1234`. The trap
handler stores `mcause` in s4 and `mtval` in s2. The expected values of s0, s1, s2 and the cause
are in the `# expect:` line at the top of each test and follow the privileged spec and Smepmp,
also where QEMU behaves differently (QEMU 11 stores the reserved PMP encoding R=0/W=1 and sets the
A bit of an invalid Svnapot PTE).

## Running

```
tests/pmp/run.sh [path/to/pasriscv/src]
```

Needs `fpc` and a `riscv64-linux-gnu-` binutils/gcc. The source directory defaults to
`../../src`, the externals to `<src>/../externals` (`EXTDIR`). Output goes to `out/` (or `WORK`).
`PMPProbe` single steps the interpreter, so these tests do not exercise the JIT.
