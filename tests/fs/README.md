# File system tests

Host side tests for the qid and the error codes of the 9P file system. They need no guest:
`FSProbe` links the emulator unit, creates a `TPasRISCV9PFileSystemPOSIX` on a directory that
`run.sh` prepares, and drives it through the public 9P operations.

The prepared directory holds a regular file `reg`, a symbolic link `lnk` to it, a subdirectory
`dir` and a fifo `fifo`. The checks are:

- `qidtype`: the qid type of the three entries. The type is a field of `st_mode`, so a test of
  single bits made every regular file look like a symbolic link
- `qidpath`: the qid path is not the bare inode number any more (the device is mixed in) and the
  three entries differ from each other
- `errno`: a directory name of 300 characters gives ENAMETOOLONG and opening the fifo for writing
  without a reader gives ENXIO. The old mapping knew neither and turned both into EINVAL

Two related fixes are not reachable from here: the lookup counting of FUSE needs a guest that
mounts virtio-fs, and `Marshall`/`Unmarshall` are private to the unit.

## Running

```
tests/fs/run.sh [path/to/pasriscv/src]
```

Needs `fpc`. The source directory defaults to `../../src`, the externals to `<src>/../externals`
(`EXTDIR`). Output goes to `out/` (or `WORK`), which also holds the prepared directory.
