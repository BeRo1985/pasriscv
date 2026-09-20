  j done
  .align 8
trap:
  csrr s4, mcause
  csrr s2, mtval
done:
  li s11, 0x1234
1: j 1b
