# TLB tests

Bare-metal regression tests for the TLB:

- `superpage_sfence`: `sfence.vma` with an address inside a 2 MiB superpage drops all of its
  cached 4 KiB parts.
- `mprv_stale`: M-mode TLB entries from before `MPRV=1` do not serve MPRV accesses and the other
  way round.
- `mstatus_sum`: after clearing `SUM`, S-mode can not reach a user page through an entry filled with `SUM=1`.
- `mmio_store`: an MMIO TLB entry filled by a load does not let a store to a read-only mapping through.
- `mmio_sfence`: `sfence.vma` with an address drops the MMIO TLB entry of that page too.
- `mmio_gap`: a device smaller than a page (the UART) does not answer for the rest of the page.

They use the same harness, conventions and `# expect:` lines as `tests/pmp` (see its README).

```
tests/tlb/run.sh [path/to/pasriscv/src]
```
