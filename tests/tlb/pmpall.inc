  li t1, -1
  csrw pmpaddr0, t1
  li t1, 0x1f
  csrw pmpcfg0, t1
