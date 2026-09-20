# FPU NaN and NV conformance

Two guest programs for the RISC-V rules that the host FPU does not follow on its own:

* every NaN an arithmetic FP instruction produces must be the **canonical** NaN
  (`0x7fc00000` / `0x7ff8000000000000`), while x86 propagates the payload of a NaN
  operand and produces `0xffc00000` with the sign bit set on an invalid operation
* a **quiet** NaN operand alone must not raise NV; only a signaling operand or a
  genuinely invalid operation (`inf-inf`, `0*inf`, `0/0`, `sqrt` of a negative) may

## fpu_nan.elf

17 cases over both precisions, run in a loop. Uses the riscv-tests HTIF exit:

    bin/PasRISCVTest tests tests/fpu_nan/fpu_nan.elf

`a0` is `0` on success, otherwise `case*100 + 1` for a wrong value or
`case*100 + 10 + observed fflags` for wrong flags.

## jitfpu.elf

11 cases, each with its operation in a hot loop and no CSR access inside it, so that
the block is JIT compiled rather than interpreted. Note that `PasRISCVTest tests`
single steps, which turns the JIT off, so running it there only covers the
interpreter again. To exercise the JIT the program also powers the machine off
through the syscon device at `0x11100000` after storing a failure bitmask (two bits
per case, value and flags) at `0x80100000`, so a harness that calls `Run` instead of
`Step` can pick the result up from there.

## jitfpu_nvmode.elf

The same 11 cases, but the guest first writes `mpasriscvctl` (CSR `0x7d0`) with `0x0e`,
which keeps the RMM fast fixup on and additionally turns on
`JITFPUInvalidFlagEnabled`. In that mode the JIT block epilog carries the host invalid
flag into NV, so the JIT reports NV for invalid arithmetic operations instead of leaving
that to the occasional interpreter execution. The bits of that CSR are:

| bit | meaning |
| --- | --- |
| 0 | `StrictCompliantFPU`, route every scalar FP instruction through soft-float |
| 1 | apply the written value to all harts, not just this one |
| 2 | `FastRMMFixupEnabled`, RMM-exact fast mode |
| 3 | `JITFPUInvalidFlagEnabled`, JIT raises NV from the host invalid flag |

Any write flushes the compiled blocks, so the change takes effect immediately.

## jitcmp.elf

Eight cases for the comparison and half precision min/max rules, again in hot loops and
with `JITFPUInvalidFlagEnabled` turned on:

* `flt.s` and `fle.s` are signaling comparisons and must raise NV for a quiet NaN
  operand, `feq.s` is quiet and must not
* `fmin.h` and `fmax.h` must return the operand that is not a NaN, whichever side it is
  on, and the canonical half precision NaN only when both are NaN

The half precision results are XORed against the expected value and the differences are
accumulated over all iterations rather than read once at the end, so a single deviating
iteration fails the case even when another engine happens to execute the last one.

## jitminmax.elf

Ten cases for the ordering rules of `fmin`/`fmax`, accumulated the same way:

* `-0.0` counts as smaller than `+0.0` for these instructions, in both operand orders
* a destination register that is the same as the second operand must still work
* the Zfa forms `fminm.s`/`fmaxm.s` on ordinary operands

Needs `-march=rv64imafdc_zfa`.

All of them are built with:

    riscv64-unknown-elf-gcc -march=rv64imafdc -mabi=lp64d -mcmodel=medany \
      -nostdlib -nostartfiles -T link.ld <name>.S -o <name>.elf

except jitcmp.elf, which needs `-march=rv64imafdc_zfh` for the half precision cases.
