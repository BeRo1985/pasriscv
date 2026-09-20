done:
  li s11, 0x1234
  # "step" stops here, "jit" powers off through the trap handler
  ecall
1: j 1b
