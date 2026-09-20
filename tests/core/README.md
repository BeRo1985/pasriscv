# Core tests

Bare-metal regression tests for traps, AMOs on devices, the JIT, the scalar FPU and the vector
unit.

The tests use the harness of `tests/priv` (`PrivProbe`, `head.inc`, `pmacros.inc`, `tail.inc`)
and the H macros of `tests/hext`, see `tests/priv/README.md`. Every test runs in the interpreter
(single step) and with the JIT (`Machine.Run`); the JIT tests (`jit_clmul_xmm`,
`jit_exec_tlb_conflict`, `jit_stale_after_sfence`, `jit_other_mode_blocks`, `jit_stale_write_tlb`,
`jit_cbo_zero_fault`, `amocas_x0`) run their loops 20 times or more from a fresh page so that the
JIT translates them. A test with a `# jitonly` line runs with the JIT only.

- `jit_clmul_xmm`: FP values that live in XMM0/XMM1 across `clmul`/`clmulh`/`clmulr`
- `fcvt_to_int_range`: conversions to integers in the strict FPU (switched on with
  `mpasriscvctl`) saturate from 2^64 on, negative values to unsigned give 0 with NV (or NX only
  when they round to 0); the same values in the fast path, there without flags. Also checks
  that `fmv.d.x` leaves `fflags` alone (shows in the single step run) and that `mpasriscvctl`
  reads back single bits
- `fround_large`: `fround`/`froundnx` with RDN/RUP from 2^31 on
- `fadd_h_inf`: `fadd.h`/`fsub.h` of infinities (a NaN result only has to be a NaN, so that
  the test holds with `PasRISCVJITCanonicalHalfNaN` on and off)
- `fnmadd_sign_rounding`: `fnmadd` as (-a*b)-c, signed zero and directed rounding
- `static_rm`: a static rm other than `frm` in the interpreter (and back to `frm` after it),
  `fcvt.h.s`/`fcvt.h.d` (one rounding) and `fcvt.bf16.s` in every rounding mode, NaNs
- `fcvt_from_u64`: `fcvt.s.lu`/`fcvt.d.lu` from 2^63 on with one rounding
- `fs_vs_dirty`: flag-only FP instructions, vector FP and `vfmv.f.s` make FS Dirty, changed
  vector CSRs make VS Dirty
- `jit_stale_write_tlb`: S-mode patches code that M-mode runs translated, through an older
  write TLB entry of the S-mode TLB, then `fence.i`
- `jit_cbo_zero_fault`: a faulting `cbo.zero` in translated code traps precisely
- `amocas_x0`: `amocas.w/.d` with rd=x0, `amocas.q` with x0 register pairs and odd registers
- `amo_mmio`: AMOs through the bounce buffer of a device (the guest flags register of the
  shared memory device at 0x2f000008, also with rd=rs1), access faults for a device without AMO
  support (ACLINT) and for unmapped addresses (AMO, LR, `cbo.zero`)
- `vectored_exceptions`: vectored `mtvec`/`stvec`, synchronous exceptions at BASE
- `jit_exec_tlb_conflict`: a data page in the TLB slot of the code page must not leave the
  translated loop interpreted (times both cases with `rdtime`, JIT only)
- `jit_stale_after_sfence`: remapping a code page with `sfence.vma` while another page holds
  its TLB slot must drop the old translation
- `i_vector_legality`: instructions the vector spec allows must not trap (`vsetivli` with an AVL
  of 0, indexed load with vd = vs2, `vmv.x.s` with an unaligned vs2, widening with the source in
  the highest part of vd, `vfrec7.v` at LMUL 8, `vrgatherei16.vv` with an odd vs1, `vsm3me.vv`
  with vd = vs1)
- `vector_arith`: `vmadc`/`vmsbc` at SEW 64 with an all-ones operand, slide and gather
  with an index of 2^32, conversions to integers rounded down from 2^31 and 2^63, int8 to and
  from fp16 (Zvfh)
- `vfrec7_vfrsqrt7`: `vfrec7.v` and `vfrsqrt7.v` in half, single and double precision with
  subnormal inputs, the overflow of `vfrec7` following frm, and NV only for a signaling NaN
- `strict_vector`: in strict mode a masked FP compare leaves inactive mask bits alone and
  `vfwadd.wf` at SEW 16 widens its scalar (the fast path runs the same checks)
- `misaligned_amo`: misaligned AMOs trap inside a 16-byte granule as well, in the interpreter
  and with the JIT, while the aligned AMO of the same translated loop keeps working
- `jit_other_mode_blocks`: the same code page runs in M-mode and in S-mode, and after a write
  to it both modes have to run the new code (JIT only)
- `decode_traps`: xtval of ecall and ebreak, reserved code points that have to trap (c.jr with
  rs1=x0, jalr with funct3 other than 0, aes64im with bit 25, wrs.nto with a field set, cbo.zero
  with the fifth rd bit, a reserved encoding in the Zimop space), the misaligned lr.w as a load
  exception and mop.rr.7 with rd other than x0
- `fp_csr`: the fli.h table, the reserved rounding modes and funct3 of fmv.w.x, fcvtmod.w.d
  just below -2^31, a write to the read-only mtopi and the seed CSR without its enable in mseccfg

## Running

```
tests/core/run.sh [path/to/pasriscv/src]
```

Needs `fpc` and a `riscv64-linux-gnu-` binutils/gcc with the H, Svinval, Zicfiss, Zicfilp, Zimop,
Zcmop, Zacas, Zabha, Zbc, Zicboz, Zvfh and Zvksh extensions. The source directory defaults to
`../../src`, the externals to `<src>/../externals` (`EXTDIR`). Output goes to `out/` (or `WORK`).
