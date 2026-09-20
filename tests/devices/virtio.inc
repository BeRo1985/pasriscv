# virtio-mmio helpers for the virtio-rng device at 0x10057000 (queue 0, 8 entries)
# Memory: descriptor table 0x80100000, available ring 0x80101000, used ring 0x80102000,
# buffers 0x80103000
.equ VIRTIO_BASE, 0x10057000
.equ DESC, 0x80100000
.equ AVAIL, 0x80101000
.equ USED, 0x80102000
.equ BUF, 0x80103000
# RNG_INIT: reset, ACKNOWLEDGE, DRIVER, VIRTIO_F_VERSION_1, FEATURES_OK, queue 0 with 8 entries,
# DRIVER_OK; clobbers t0, t1
.macro RNG_INIT
  li t0, VIRTIO_BASE
  sw zero, 0x70(t0)
  li t1, 1
  sw t1, 0x70(t0)
  li t1, 3
  sw t1, 0x70(t0)
  li t1, 1
  sw t1, 0x24(t0)
  sw t1, 0x20(t0)
  sw zero, 0x24(t0)
  sw zero, 0x20(t0)
  li t1, 11
  sw t1, 0x70(t0)
  sw zero, 0x30(t0)
  li t1, 8
  sw t1, 0x38(t0)
  li t1, DESC
  sw t1, 0x80(t0)
  sw zero, 0x84(t0)
  li t1, AVAIL
  sw t1, 0x90(t0)
  sw zero, 0x94(t0)
  li t1, USED
  sw t1, 0xa0(t0)
  sw zero, 0xa4(t0)
  li t1, 1
  sw t1, 0x44(t0)
  li t1, 15
  sw t1, 0x70(t0)
.endm
# DESCRIPTOR index, address, length, flags, next; clobbers t0, t1
.macro DESCRIPTOR index, address, length, flags, next
  li t0, DESC+(\index*16)
  li t1, \address
  sd t1, 0(t0)
  li t1, \length
  sw t1, 8(t0)
  li t1, \flags
  sh t1, 12(t0)
  li t1, \next
  sh t1, 14(t0)
.endm
# SUBMIT head: puts the chain head into available ring slot 0, sets idx to 1 and notifies queue 0
.macro SUBMIT head
  li t0, AVAIL
  sh zero, 0(t0)
  li t1, \head
  sh t1, 4(t0)
  li t1, 1
  sh t1, 2(t0)
  fence
  li t0, VIRTIO_BASE
  sw zero, 0x50(t0)
.endm
