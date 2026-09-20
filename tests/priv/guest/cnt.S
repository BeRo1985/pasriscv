# cnt t|c|i: reads time, cycle or instret in U-mode and exits with 0; a denied read ends the
# process with SIGILL (shell status 132)
  .globl _start
_start:
  ld a1, 16(sp)
  lbu a2, 0(a1)
  li t0, 'c'
  beq a2, t0, 1f
  li t0, 'i'
  beq a2, t0, 2f
  rdtime a3
  j 3f
1:
  rdcycle a3
  j 3f
2:
  rdinstret a3
3:
  li a0, 0
  li a7, 93
  ecall
