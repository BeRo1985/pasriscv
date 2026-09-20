# H extension tests

Bare-metal regression tests for the hypervisor extension.

Each test starts in M-mode (`head.inc`: PMP opened for S/U, trap handler), sets up what it needs
and enters HS-, VS- or VU-mode with the macros from `hmacros.inc`: `GSTAGE_IDENTITY` builds an
Sv39x4 G-stage table at 0x80100000 that maps GPA 0x80000000 (1 GiB) 1:1, `GSTAGE_ALIAS perm` maps
GPA 0xC0000000 to host 0x80000000 with the given PTE flags, `ENTER_VS`/`ENTER_HS` use `mret`.

The M-mode trap handler records `mcause` in s4, `mtval` in s2, `mtval2` in s3, `mtinst` in s5 and
`mstatus` in s6 (GVA is bit 38, MPV bit 39) and counts traps in s10. It resumes after the trapping
instruction (at it for an interrupt), or continues in M-mode at s8 when s8 is set. Tests keep
their results in a0 to a7 (and s0, s1). The `# expect:` line lists the registers to check as 16
uppercase hex digits; a `# aia` line runs the test with the AIA (IMSIC with a guest interrupt
file). The expected values follow the privileged spec, the H extension and the AIA spec.

## Running

```
tests/hext/run.sh [path/to/pasriscv/src]
```

Needs `fpc` and a `riscv64-linux-gnu-` binutils/gcc (with the H and Svinval extensions). The
source directory defaults to `../../src`, the externals to `<src>/../externals` (`EXTDIR`).
Output goes to `out/` (or `WORK`). `HProbe` single steps the interpreter (at most 20000 steps),
so these tests do not exercise the JIT.

## KVM check

Beyond these tests the fixes were checked with Linux KVM inside an Alpine guest: the KVM module
loads ("hypervisor extension available", Sv57x4 G-stage), and a small static KVM user space
program (no libc) runs a VM with MMIO exits, a lazily mapped guest page, a VS timer interrupt
(arrives as `scause` 0x8000000000000005) and an SBI SRST shutdown. That run found two further
bugs: HS-`sret` with SPV=1 read `sepc` only after the swap of the S-CSRs, and HINVAL.VVMA and
HINVAL.GVMA were decoded at the funct7 values of SFENCE (see `hinval.S`).

The program is `kvm/kvmtest.c`. Build it with

```
riscv64-linux-gnu-gcc -O2 -static -nostdlib -ffreestanding -fno-stack-protector -fno-pic -no-pie \
  -march=rv64gc -mabi=lp64d -s -o kvmtest kvm/kvmtest.c
```

copy it into the guest (for example base64 through the console), then `modprobe kvm` and run it.
It prints every exit and ends with `KVMTEST PASSED`. The expected output is (plus a line `OK`
when the host kernel forwards the SBI v0.1 console, the Alpine kernel does not):

```
MMIO write 0x0000000010000000 0x00000000000013ba
MMIO write 0x0000000010000008 0x0000000000001234
MMIO write 0x0000000010000010 0x8000000000000005
SYSTEM_EVENT 0x0000000000000001
KVMTEST PASSED
```
