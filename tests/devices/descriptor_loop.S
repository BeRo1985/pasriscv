# A descriptor chain that loops (0 -> 1 -> 0, both device-writable) must not hang the device:
# It walks at most as many descriptors as the queue has and then signals DEVICE_NEEDS_RESET. After
# a reset a normal request works again (16 random bytes, used length 16).
# expect: a0=0000000000000040 a1=0000000000000001 a2=0000000000000010
#include "../hext/head.inc"
#include "virtio.inc"
  RNG_INIT
  DESCRIPTOR 0, BUF, 16, 3, 1              # WRITE | NEXT -> 1
  DESCRIPTOR 1, BUF+16, 16, 3, 0           # WRITE | NEXT -> 0: a loop
  SUBMIT 0
  li t2, 100000
1:
  li t0, VIRTIO_BASE
  lw a0, 0x70(t0)
  andi a0, a0, 0x40                        # DEVICE_NEEDS_RESET
  bnez a0, 2f
  addi t2, t2, -1
  bnez t2, 1b
2:
  # Reset, then one valid request
  li t0, USED
  sd zero, 0(t0)
  RNG_INIT
  DESCRIPTOR 0, BUF, 16, 2, 0              # WRITE only
  SUBMIT 0
  li t2, 100000
3:
  li t0, USED
  lhu a1, 2(t0)                            # used idx
  bnez a1, 4f
  addi t2, t2, -1
  bnez t2, 3b
4:
  lwu a2, 8(t0)                            # used ring[0].len
  j done
#include "../hext/tail.inc"
