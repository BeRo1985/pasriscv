OUTPUT_ARCH(riscv)
ENTRY(_start)

/* Layout matches what the riscv-tests harness in PasRISCVTest expects:
   the image is loaded at physical 0x80000000, and tohost/fromhost sit at
   offset 0x1000/0x1040 into it. */
SECTIONS
{
  . = 0x80000000;
  .text.init : { *(.text.init) }

  . = 0x80001000;
  .tohost : { *(.tohost) }

  . = 0x80002000;
  .pagetables : { *(.pagetables) }

  .data : { *(.data) *(.data.*) *(.rodata) *(.rodata.*) }

  /DISCARD/ : { *(.comment) *(.note*) *(.riscv.attributes) }
}
