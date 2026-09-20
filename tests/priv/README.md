# Privilege tests

Bare-metal regression tests for the privilege levels: counter enables, M-level ID CSRs,
sret/sfence.vma/wfi at V=1, FS=Off, Zicfilp landing pads and Zicfiss shadow stacks.

Every test runs twice: single stepped in the interpreter (`step`) and with `Machine.Run` and the
JIT (`jit`). The JIT tests (`landing_pads_jit`, `fs_jit`, `csr_read_jit`) run their loops 20 times
from a fresh page, so that the JIT translates them, and then change state the translation depends
on (FS, the landing pad enables, the counter enables): the old JIT kept running the old
translation.

The harness is the one of `tests/hext` (the H macros come from `../hext/hmacros.inc`), with a few
differences in `head.inc`: a0 to a7 start at zero, the M-mode trap handler resumes after a 2 or
4 byte instruction (it reads the instruction at `mepc`, so the code has to be identity mapped
there, and a fetch fault needs s8), and once s11 is set it powers off through SYSCON, which ends
the `jit` run. `pmacros.inc` adds `ENTER_U`, `ENTER_VU`, `SRET_U`, `TO_M` (back to M-mode with
an ecall) and `PROBE`/`PROBE8`, which record the `mcause` of an instruction (0 without a trap),
`PROBE8` one byte per probe in the same register. The `# expect:` line lists the registers to
check as 16 uppercase hex digits. The expected values follow the privileged spec, the H
extension and the Zicfilp/Zicfiss chapters.

## Running

```
tests/priv/run.sh [path/to/pasriscv/src]
```

Needs `fpc` and a `riscv64-linux-gnu-` binutils/gcc with the H, Svinval, Zicfiss, Zicfilp, Zimop
and Zcmop extensions. The source directory defaults to `../../src`, the externals to
`<src>/../externals` (`EXTDIR`). Output goes to `out/` (or `WORK`).

## Guest check

`guest/cnt.S` is a tiny static Linux program that reads `time`, `cycle` or `instret` from U-mode
(argument `t`, `c` or `i`). Build it with

```
riscv64-linux-gnu-gcc -nostdlib -static -s -o cnt guest/cnt.S
```

copy it into the guest (for example base64 through the console) and run
`for x in t c i; do ./cnt $x; echo "$x=$?"; done`. With the Linux default
`kernel.perf_user_access=1` the expected result is `t=0 c=132 i=132` (132 = SIGILL: the kernel
only allows `time` in `scounteren`), the same as on real hardware. The emulator let all three
through before the fix.
