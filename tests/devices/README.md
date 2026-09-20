# Device tests

Bare-metal regression tests for the devices. They use `HProbe`, the head/tail includes and the
macros of `tests/hext`, and the same `# expect:` format (registers s0 to s10 and a0 to a7 as 16
uppercase hex digits).

- `descriptor_loop.S`: drives the virtio-rng device (virtio-mmio at 0x10057000) with a
  descriptor chain that loops. The device has to stop after at most queue-size descriptors and
  signal DEVICE_NEEDS_RESET (the old code walked the loop forever and hung the emulator), and after
  a reset a normal request has to work.

`virtio.inc` has small virtio-mmio helpers (device init, descriptors, submit).

## Running

```
tests/devices/run.sh [path/to/pasriscv/src]
```

Needs `fpc` and a `riscv64-linux-gnu-` binutils/gcc. Output goes to `out/` (or `WORK`).

## Checks in the Linux guest

The 9P and virtio-fs fixes (the leaking descriptors, the lock semantics and the directory fsync)
were checked in the Alpine guest with both shares mounted (`mount -t 9p -o trans=virtio,version=9p2000.L extern /mnt/p9`,
`mount -t virtiofs extern /mnt/vfs`): 3000 opens of a file over 9P with the open descriptors of
the emulator counted on the host (constant now, before one leaked descriptor per open), `flock`
and `fcntl` locks over 9P (the old code hung in Tlock), and `fsync` of a directory over virtio-fs
(EIO before). `fsynctest.c` is the small static helper for the fsync and fcntl part.

Two later fixes were checked in the same guest. Over 9P a shell changes into a directory of the
share and renames it from there (`cd .../ren/a; mv .../ren/a .../ren/b`): `ls .`, `cat f` and
`stat f` work afterwards, before the fix the fid still pointed at the old name and all three gave
ENOENT. Over virtio-fs `fhtest.c` creates a file, keeps it open, unlinks it and truncates it
through the descriptor, which is the one attribute change that Linux sends with `FATTR_FH`; that
also gave ENOENT before.
