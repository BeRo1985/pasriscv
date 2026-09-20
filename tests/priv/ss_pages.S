# Shadow stack pages (xwr=010) in Sv39 with menvcfg.SSE=1. VA 0x40000000 is a supervisor
# SS page, 0x40001000 a read-write page, 0x40002000 a read-only page and 0x40003000 a user SS page
# (the same physical page as 0x40000000); the code runs from a gigapage at 0x80000000 and, for
# U-mode, from its user alias at 0xC0000000.
# - sspush, sspopchk and ssamoswap work on SS pages, ordinary loads read them, an ordinary store
#   is a store/AMO access fault (7), an instruction fetch an instruction access fault (1)
# - shadow stack accesses to a read-only page are store/AMO page faults (15, also for sspopchk),
#   to any other page, and misaligned ones, store/AMO access faults; the faults leave ssp alone
# - ssamoswap.w sign extends
# - U and SUM apply as usual: S-mode needs SUM for the user SS page, U-mode can not use the
#   supervisor SS page (15)
# - with menvcfg.SSE=0 xwr=010 is reserved again (load page fault 13, store page fault 15)
# - PMP has to grant read and write for shadow stack accesses: sspopchk from a read-only PMP
#   region is a store/AMO access fault, an ordinary load works
# expect: a0=0000000040000FF8 a1=0000000001234567 a2=0000000000000700 s0=0000000040001000 a3=000000070F0F0707 s1=0000000040002FF8 a4=0000000000005A5A a5=0000000000000077 a6=FFFFFFFF80000000 a7=0F000F010D0F0700
#include "head.inc"
  # Sv39 root at 0x80200000: 0x80000000 and 0xC0000000 gigapages, 0x40000000 through L1 and L0
  li t0, 0x80200000
  li t1, 0x200000cf
  sd t1, 16(t0)
  li t1, 0x200000df
  sd t1, 24(t0)
  li t1, 0x20080401
  sd t1, 8(t0)
  li t0, 0x80201000
  li t1, 0x20080801
  sd t1, 0(t0)
  li t0, 0x80202000
  li t1, 0x200c00c5
  sd t1, 0(t0)
  li t1, 0x200c04c7
  sd t1, 8(t0)
  li t1, 0x200c0843
  sd t1, 16(t0)
  li t1, 0x200c00d5
  sd t1, 24(t0)
  li t0, 0x80300000
  li t1, 0x5a5a
  sd t1, 0(t0)
  li t1, 0x80000000
  sw t1, 16(t0)
  li t0, 0x8000000000080200
  csrw satp, t0
  sfence.vma
  li t0, 8
  csrs menvcfg, t0
  ENTER_HS s1
s1:
  li ra, 0x1234567
  li t0, 0x40001000
  csrw ssp, t0
  li t1, 0x40000ff8
  PROBE8 a2, sspush ra
  csrr a0, ssp
  PROBE8 a2, ld a1, 0(t1)
  PROBE8 a2, sd zero, 0(t1)
  PROBE8 a2, sspopchk ra
  csrr s0, ssp
  # read-write page, read-only page
  li t0, 0x40002000
  csrw ssp, t0
  PROBE8 a3, sspush ra
  li t0, 0x40003000
  csrw ssp, t0
  PROBE8 a3, sspush ra
  li t0, 0x40002ff8
  csrw ssp, t0
  PROBE8 a3, sspopchk ra
  csrr s1, ssp
  li t1, 0x40001000
  li t2, 0x77
  PROBE8 a3, ssamoswap.d t0, t2, (t1)
  li t1, 0x40000004
  PROBE8 a3, ssamoswap.d t0, t2, (t1)
  # ssamoswap on the SS page
  li t1, 0x40000000
  li a4, -1
  ssamoswap.d a4, t2, (t1)
  ld a5, 0(t1)
  li t1, 0x40000010
  li t2, 0x12345678
  li a6, -1
  ssamoswap.w a6, t2, (t1)
  # user SS page from S-mode without and with SUM
  li t0, 0x40004000
  csrw ssp, t0
  PROBE8 a7, sspush ra
  li t0, 1 << 18
  csrs sstatus, t0
  PROBE8 a7, sspush ra
  csrc sstatus, t0
  TO_M m1
m1:
  # U-mode (senvcfg.SSE=1, running from the user alias) pushes to the supervisor SS page
  li t0, 8
  csrs senvcfg, t0
  li t0, 0x40001000
  csrw ssp, t0
  li t0, 0x1800
  csrc mstatus, t0
  lla t0, u1
  li t1, 0x40000000
  add t0, t0, t1
  csrw mepc, t0
  lla s8, m2
  li s4, 0
  mret
u1:
  sspush ra
  ecall
m2:
  slli a7, a7, 8
  or a7, a7, s4
  ENTER_HS s2
s2:
  # instruction fetch from the SS page
  lla s8, s3
  li s4, 0
  li t0, 0x40000000
  jr t0
s3:
  slli a7, a7, 8
  or a7, a7, s4
  TO_M m3
m3:
  # menvcfg.SSE=0
  li t0, 8
  csrc menvcfg, t0
  ENTER_HS s4
s4:
  li t1, 0x40000000
  PROBE8 a7, ld t0, 0(t1)
  PROBE8 a7, sd zero, 0(t1)
  TO_M m4
m4:
  # PMP: the physical SS page read-only for S- and U-mode
  li t0, 8
  csrs menvcfg, t0
  li t0, 0x200c01ff
  csrw pmpaddr0, t0
  li t0, -1
  csrw pmpaddr1, t0
  li t0, 0x1f19
  csrw pmpcfg0, t0
  ENTER_HS s5
s5:
  li t0, 0x40000ff8
  csrw ssp, t0
  PROBE8 a7, sspopchk ra
  li t1, 0x40000ff8
  PROBE8 a7, ld t0, 0(t1)
  TO_M m5
m5:
  j done
#include "tail.inc"
