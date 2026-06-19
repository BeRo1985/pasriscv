# `Xpasriscvctl` — PasRISCV Emulator Control Extension

**Extension name:** `xpasriscvctl`  
**Version:** 1.0  
**Status:** Non-standard, PasRISCV-specific  
**Privilege level:** Machine (M-mode)  
**ISA string token:** `xpasriscvctl`  

---

## 1. Introduction

The `Xpasriscvctl` extension defines a single machine-mode read/write Control and Status Register (CSR), `mpasriscvctl` (address `0x7D0`), which exposes runtime control over PasRISCV-specific emulator features to guest software running at M-mode privilege.

The first defined feature is **per-HART IEEE 754-2008 strict-compliant FPU mode** (`StrictCompliantFPU`). When this mode is active on a given HART, all scalar and vector floating-point operations are executed via a software IEEE 754-2008 compliant implementation (SoftFloat) rather than the host processor's FPU. This guarantees exact compliance with the RISC-V floating-point specification, including correct NaN propagation, denormal handling, rounding modes, and exception flag generation, at the cost of reduced performance.

A second feature is **per-HART RMM-exact fast mode** (`FastRMMFixupEnabled`). It is a lightweight middle tier between the default fast (host-FPU/JIT) mode and full strict mode: while it is active, only floating-point operations whose effective rounding mode is **RMM** (round-to-nearest, ties-to-max-magnitude / IEEE roundTiesToAway) are routed through the soft-float core, which rounds RMM ties correctly; all other rounding modes keep running on the host FPU and JIT at full speed. This closes the one rounding-mode gap of the fast mode (the host FPU has no roundTiesToAway mode and otherwise approximates RMM as round-to-nearest-even) without paying the strict-mode cost on the common rounding modes. It depends on `StrictCompliantFPU` being compiled in (it reuses the same soft-float routines) and is a no-op when `StrictCompliantFPU` mode (bit 0) is already active.

This extension is intentionally minimal: it occupies one CSR in the vendor-reserved machine-mode range (`0x7C0`–`0x7FF`) and adds no new instructions.

### Rationale

Different guest workloads have different FPU compliance requirements:

- **General-purpose software** (operating systems, applications, games): host-FPU execution is sufficient and provides maximum performance including JIT code generation and hardware acceleration, even if it may not be fully IEEE 754-2008 compliant.
- **Numerically sensitive software** (scientific computing, financial calculations, reproducible builds, compliance test suites): strict IEEE 754-2008 behaviour is required, including exact exception flags and deterministic results across platforms.

The `Xpasriscvctl` extension allows guest firmware or an operating system to select the appropriate mode per HART at runtime, without requiring a full emulator restart or recompilation.

---

## 2. CSR Summary

| CSR Name       | Address | Privilege | Access | Reset Value |
|----------------|---------|-----------|--------|-------------|
| `mpasriscvctl` | `0x7D0` | M-mode    | R/W    | `0x0`       |

---

## 3. CSR Definition: `mpasriscvctl`

**Address:** `0x7D0`  
**Full name:** Machine PasRISCV Control Register  
**Privilege:** Machine-mode only. Any access from S-mode or U-mode raises an `IllegalInstruction` exception.

### 3.1 Bit Fields

```
 63                          3      2        1          0
┌───────────────────────────────┬────────┬──────────┬────────┐
│        WPRI (reserved, 0)     │  FRMM  │ BROADCAST│  SFPU  │
└───────────────────────────────┴────────┴──────────┴────────┘
```

| Bit | Name        | Access | Description |
|-----|-------------|--------|-------------|
| 0   | `SFPU`      | R/W    | **StrictCompliantFPU** — When `1`, all FP operations on this HART use the software IEEE 754-2008 compliant soft-float implementation. When `0`, the host FPU is used and JIT host native code generation may be employed for maximum performance, but with potentially non-compliant behaviour (e.g., flush-to-zero for denormals, differing NaN payloads). |
| 1   | `BROADCAST` | W-only | **Broadcast** — Write-only control bit. When `1` on a write, the new values of `SFPU` (bit 0) and `FRMM` (bit 2) are propagated atomically to all HARTs in the machine. Always reads as `0`. |
| 2   | `FRMM`      | R/W    | **FastRMMFixupEnabled** — When `1` (and `SFPU=0`), FP operations whose effective rounding mode is RMM (roundTiesToAway) are evaluated by the soft-float core so RMM ties round correctly, while all other rounding modes keep running on the host FPU/JIT. When `0`, RMM is approximated as round-to-nearest-even in fast mode. Has no effect while `SFPU=1` (strict mode already covers RMM). |
| 63:3 | —          | WPRI   | Reserved. Must be written as zero, reads as zero. |

### 3.2 Reset Behaviour

On reset, `mpasriscvctl` is `0x0`: `SFPU=0` (host FPU), `BROADCAST=0`, `FRMM=0`. The emulator may be started with `SFPU=1` and/or `FRMM=1` pre-set on all HARTs via configuration (`StrictCompliantFPU` / `FastRMMFixupEnabled`), in which case the reset value reflects those bits.

### 3.3 WARL Behaviour

Bits 63:3 are WARL (Write Any, Read Legal) and always return `0`. Bit 1 (`BROADCAST`) always reads `0` regardless of what was written. Bits 0 (`SFPU`) and 2 (`FRMM`) are persistent and readable.

---

## 4. Functional Description

### 4.1 StrictCompliantFPU Mode (SFPU)

When `SFPU=1` on a HART, every scalar and vector floating-point instruction executed by that HART is handled by a software IEEE 754-2008 compliant implementation. This affects:

- All scalar FP instructions: `fadd`, `fsub`, `fmul`, `fdiv`, `fsqrt`, `fmadd`, `fmsub`, `fnmadd`, `fnmsub`, `fmin`, `fmax`, `fcmp`, `fcvt`, `fmv`
- All vector FP instructions: `vfadd`, `vfsub`, `vfmul`, `vfdiv`, `vfsqrt`, `vfmadd` (and variants), `vfmin`, `vfmax`, `vmfeq`, `vmflt`, `vmfle`, `vmfne`, `vmfgt`, `vmfge`, `vfwadd`, `vfwsub`, `vfwmul`, `vfwmacc` (and widening variants), `vfredusum`, `vfredosum`, `vfredmin`, `vfredmax`

Instructions that do not perform arithmetic (e.g., `vfsgnj`, `vfmv`, `vfmerge`, `vfclass`, `vfslide1up`, `vfslide1down`, `vfcvt.*`) are unaffected by this mode.

When `SFPU=0`, all FP instructions use the host processor's FPU and are subject to host-FPU behaviour, which may not be fully IEEE 754-2008 compliant (e.g., flush-to-zero for denormals, differing NaN payloads).

### 4.2 RMM-exact Fast Mode (FRMM)

When `FRMM=1` and `SFPU=0`, the HART stays in fast (host-FPU/JIT) mode for every rounding mode except **RMM** (round-to-nearest, ties-to-max-magnitude / IEEE roundTiesToAway). Operations whose *effective* rounding mode is RMM — either a static `rm` instruction field of `0b100`, or a dynamic `rm` (`0b111`) while `frm = RMM` — are instead evaluated by the soft-float core, which rounds halfway ties to the larger magnitude as the specification requires. This covers `fadd`, `fsub`, `fmul`, `fdiv` and the fused multiply-add family (`fmadd`/`fmsub`/`fnmadd`/`fnmsub`); `fsqrt` never needs it (a square-root result is never an exact halfway tie).

The motivation: the host FPU has no roundTiesToAway mode, so the default fast mode runs RMM in round-to-nearest-even, which differs from RMM only on exact halfway ties. `FRMM` closes that gap at the cost of running just the (uncommon) RMM operations in software, leaving all other rounding modes at full host/JIT speed.

Interaction with the JIT: while `FRMM=1`, a write to `frm` that crosses the RMM boundary invalidates the HART's compiled JIT blocks so that dynamic-rounding FP traces are rebuilt under the new policy. Because `frm` writes are infrequent, this has negligible aggregate cost. `FRMM` has no effect while `SFPU=1`, since strict mode already evaluates every operation (including RMM) in software.

### 4.3 Broadcast Semantics

Writing `mpasriscvctl` with `BROADCAST=1` sets `SFPU` and `FRMM` on the writing HART **and** propagates their new values to all other HARTs in the machine. This allows a single `csrw` from the boot HART to apply a consistent FPU policy globally.

The broadcast is performed synchronously within the CSR write. No inter-HART synchronisation fences are required by the writer; however, other HARTs will observe the updated value no later than their next FP instruction execution.

### 4.4 Per-HART Independence

Without `BROADCAST`, each HART maintains independent `SFPU` and `FRMM` values. Mixed configurations are valid (e.g., one HART in strict mode, others in host-FPU mode, others in RMM-exact fast mode), which may be useful for isolation or testing purposes.

---

## 5. Discovery

Guest software detects `Xpasriscvctl` support via the ISA string. In the device tree, the CPU node's `riscv,isa` or `riscv,isa-extensions` property includes the token `xpasriscvctl`:

```
cpu@0 {
    compatible = "riscv";
    riscv,isa = "rv64imafdc_zicsr_zifencei_..._xpasriscvctl";
    riscv,isa-extensions = "...", "xpasriscvctl";
};
```

Software should probe for the extension before accessing `mpasriscvctl`. On implementations that do not support this extension, a `csrr`/`csrw` to `0x7D0` will raise `IllegalInstruction`.

---

## 6. Programming Examples

### 6.1 Enable StrictCompliantFPU on all HARTs (global)

```asm
/* Enable SFPU on all HARTs (BROADCAST=1, SFPU=1 → value=3) */
li   a0, 3
csrw 0x7d0, a0
```

### 6.2 Disable StrictCompliantFPU on all HARTs (global)

```asm
/* Disable SFPU on all HARTs (BROADCAST=1, SFPU=0 → value=2) */
li   a0, 2
csrw 0x7d0, a0
```

### 6.3 Enable StrictCompliantFPU on this HART only

```asm
/* Set SFPU=1 on this HART only */
csrsi 0x7d0, 1
```

### 6.4 Disable StrictCompliantFPU on this HART only

```asm
/* Clear SFPU on this HART only */
csrci 0x7d0, 1
```

### 6.5 Read current SFPU state

```asm
/* Read SFPU state into a0; bit 0 = StrictCompliantFPU */
csrr  a0, 0x7d0
andi  a0, a0, 1
```

### 6.6 Save and restore

```asm
/* Save */
csrr  s0, 0x7d0

/* Enable strict FPU for sensitive computation */
csrsi 0x7d0, 1
/* ... floating-point work ... */

/* Restore previous state */
csrw  0x7d0, s0
```

### 6.7 Enable RMM-exact fast mode on this HART only

```asm
/* Set FRMM=1 (bit 2) on this HART only — keeps host-FPU/JIT speed for all
   rounding modes except RMM, which becomes exact. Leaves SFPU untouched. */
csrsi 0x7d0, 4
```

---

## 7. Interaction with Other Extensions

| Extension | Interaction |
|-----------|-------------|
| F, D, Q   | `SFPU=1` replaces host-FPU scalar operations with SoftFloat. All rounding modes (`frm`) and exception flags (`fflags`) are handled correctly by the software implementation. `FRMM=1` (with `SFPU=0`) does the same only for RMM-rounded `fadd`/`fsub`/`fmul`/`fdiv`/`fmadd`-family operations, leaving the other rounding modes on the host FPU. |
| Zfh / Zvfh | Half-precision (F16) operations are also covered by the software implementation when `SFPU=1`. |
| V (Vector) | All vector FP instructions listed in §4.1 are handled by per-element SoftFloat loops when `SFPU=1`. |
| Zicsr | Required. `mpasriscvctl` is accessed via standard `csrrw`/`csrrs`/`csrrc` instructions. |
| `-strictcompliantfpu` CLI | Sets `SFPU=1` on all HARTs at machine startup. Guest can override at runtime via `mpasriscvctl`. |

---

## 8. Version History

| Version | Changes |
|---------|---------|
| 1.0     | Initial definition. CSR `mpasriscvctl` at `0x7D0`. Bits: `SFPU` (bit 0), `BROADCAST` (bit 1), `FRMM` (bit 2). |
