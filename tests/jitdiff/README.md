# JIT differential tests

Bare-metal test programs that compare the JIT against the interpreter and, when available,
against QEMU.

The riscv-tests run via `Machine.Step`, and in single step mode the emulator discards the JIT
translation, so they never exercise the JIT. These tests use `Machine.Run` instead.

## Tests

- `gen.sh` generates `jitdiff.S`: every integer instruction the JIT translates (RV64IM, Zba,
  Zbb, Zbs, Zbc, Zbkb, Zbkx, Zknh, Zksh, Zkne/Zknd, Zksed, Zicond, Zcb and the compressed ALU
  forms) in all register aliasing combinations (rd=rs1, rd=rs2, rs1=rs2, all equal) with five
  value sets. The body runs four times: the first pass is interpreted while the JIT traces, the
  later passes run the translated blocks. After each test a0..a3 are stored, so clobbered
  sources show up as well.
- `vsetvli_alias.S`: `vsetvli` and `slli.uw` with rd=rs1 in a loop with stable vtype, so that
  the translated block really runs.
- `vecfp.S`: vector and floating point checks (strict `fsqrt` for f16/f32/f64 including fflags,
  vector shift immediates, `vwmaccsu`, `vmacc.vx` family, narrowing with vd=vs2, `c.ntl.*`
  HINTs). Traps are counted and must stay at zero.
- `gen_pressure.sh` generates `pressure.S`: blocks that first map up to 28 guest
  registers and then do `flh`/`fsh` with offset 0 and a nonzero offset and FP operations with a
  static rounding mode, so that address registers land in RBX, RBP, R12, R13 and so on and the
  code inside the MXCSR window has to reclaim callee-saved host registers. The old JIT hung here.
- `nofeatures`: `jitdiff`, `pressure` and `vecfp` again with a JIT that sees no LZCNT, BMI1,
  POPCNT and F16C on the host, so the intrinsics that need them decline and the
  interpreter runs those instructions.

All loops start on a fresh page: after a TLB flush the JIT only finds its blocks again once the
interpreter refetches through the TLB, which would otherwise keep a small test interpreted.

## Running

```
tests/jitdiff/run.sh [path/to/pasriscv/src]
```

Needs `fpc`, a `riscv64-linux-gnu-` binutils/gcc and optionally `qemu-system-riscv64`
(`-cpu max,vlen=256` is used as the reference). The source directory defaults to `../../src`;
the externals default to `<src>/../externals` and can be set with `EXTDIR`. Build output and
signatures go to `out/` (or `WORK`). The exit status is 0 when every comparison matches.

`cmp.sh <desc.txt> <ref.txt> <test.txt>` names every differing register of a `jitdiff`
signature, for example `pass 2 test 1234 a1: sha256sum0 a1, a1 | a1=... ref=... got=...`.
