# PasRISCV

A RISC-V RV64GC emulator written in Object Pascal. It simulates processor cores, memory, I/O, and much more.

## Features

- RV64GC instruction set support with these ISA extensions:  
  - M (Integer Multiplication and Division)  
  - A (Atomic Operations)  
  - F (Single-Precision Floating-Point)  
  - D (Double-Precision Floating-Point)  
  - C (Compressed Instructions)
  - Zicsr (Control and Status Register)
  - Zifencei (Instruction-Fetch Fence)
  - Zicond (Conditional stuff)
  - Zkr (Entropy source)
  - Zicboz (Cache-Block Zero Instructions)
  - Zicbom (Cache-Block Management Instructions)
  - Svadu (Hardware Updating of PTE A/D Bits) 
  - Sstc (RISC-V "stimecmp / vstimecmp" Extension)
  - Snapot (“NAPOT Translation Continuity)
  - Zbb/Zcb/Zbs/Zba (Bit Manipulations)
  - Zacas (Atomic Compare-And-Swap)
- Multi-core SMP support
- Emulated peripherals
  - ACLINT
  - PLIC
  - UART NS16550A
  - SysCon   
  - VirtIO MMIO with following devices support
    - Block
    - Network
    - Random/Entropy
    - 9P filesystem
    - Keyboard
    - Mouse
    - Sound
  - Framebuffer support
  - PS/2 keyboard and mouse
  - Raw keyboard input with scancode bit-array (for more direct input per polling) 
  - DS1742 real-time clock (read-only, no write support)
  - PCIe Bus
    - NVMe SSD
  - I2C bus (disabled for now, due to IRQ issues, will be either fixed, removed, or replaced with virtio-i2c later)
    - HID devices
      - Keyboard
- GDB remote debugging support (partially implemented)
  - Own GDB server implementation

## Usage

See [pasriscvemu](https://github.com/BeRo1985/pasriscvemu) PasVulkan project for an emulator frontend that uses this library.

## Documentation

See the `docs` directory for more information.

## Related connected repositories

- [PasRISCV Third-Party Software Repository](https://github.com/BeRo1985/pasriscv_software) - This repository contains third-party software, including test cases, guest Linux system build scripts, and other related assets, for the PasRISCV Emulator — a RV64GC RISC-V emulator developed in Object Pascal. Needed for the test suite and other related assets.
- [PasVulkan](https://github.com/BeRo1985/pasvulkan) - PasVulkan game engine and Vulkan API bindings for Object Pascal.
- [pasriscemu](https://github.com/BeRo1985/pasriscvemu) - PasRISCV Emulator frontend using PasVulkan.

## License

This project is released under zlib license.
