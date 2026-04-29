# PasRISCV

A RISC-V RV64GCV/RVA23 emulator written in Object Pascal. It simulates processor cores, memory, I/O, and much more.

## Features

- RV64GCV/RVA23 instruction set support with these ISA extensions:  
  - M (Integer Multiplication and Division)  
  - A (Atomic Operations)  
  - F (Single-Precision Floating-Point)  
  - D (Double-Precision Floating-Point)  
  - C (Compressed Instructions)
  - Zicsr (Control and Status Register)
  - Zifencei (Instruction-Fetch Fence)
  - Zicond (Conditional stuff)
  - Zicntr (Base Counters and Timers)
  - Zihpm (Hardware Performance Counters)
  - Zkr (Entropy source)
  - Zicbom (Cache-Block Management Instructions)
  - Zicbop (Prefetch Hints)
  - Zicboz (Cache-Block Zero Instructions)
  - Zic64b (64-Byte Cache Blocks)
  - Ziccif (Instruction Fetch Coherence)
  - Ziccrse (LR/SC Forward Progress)
  - Ziccamoa (AMO on Main Memory)
  - Ziccamoc (Cacheability on Main Memory)
  - Zicclsm (Misaligned Load/Store Support)
  - Za64rs (64-Byte Reservation Set)
  - Svadu (Hardware Updating of PTE A/D Bits) 
  - Svade (Page-Fault on A/D Bit Violations)
  - Sscofpmf (Count Overflow and Mode-Based Filtering)
  - Sstc (RISC-V "stimecmp / vstimecmp" Extension)
  - Ssccptr (Main Memory Page-Table Reads)
  - Sstvecd (stvec Direct Mode)
  - Sstvala (stval Written on Faults)
  - Sscounterenw (Writable scounteren)
  - Ssu64xl (UXLEN=64)
  - Ssstateen (Supervisor-Mode State Enable)
  - Ssstrict (No Non-Conforming Extensions)
  - Ssqosid (Quality-of-Service Identifiers)
  - Svbare (satp Bare Mode)
  - Ss1p13 (Supervisor Architecture v1.13)
  - Sm1p13 (Machine Architecture v1.13)
  - Smcsrind (Machine-Level CSR Indirect Access)
  - Smcntrpmf (Counter Privilege-Mode Filtering) *(compile-time optional, see `{$define PasRISCVSmcntrpmf}`)*
  - Smrnmi (Resumable Non-Maskable Interrupts)
  - Smdbltrp (Machine-Mode Double Trap) *(compile-time optional, see `{$define PasRISCVSmdbltrp}`)*
  - Ssdbltrp (Supervisor-Mode Double Trap) *(compile-time optional, see `{$define PasRISCVSsdbltrp}`; requires Smdbltrp)*
  - Sscsrind (Supervisor-Level CSR Indirect Access)
  - Smaia (Machine-Level Advanced Interrupt Architecture, when AIA is enabled)
  - Ssaia (Supervisor-Level Advanced Interrupt Architecture, when AIA is enabled)
  - Supm (User-Mode Pointer Masking)
  - Ssnpm (Supervisor-Mode Non-Privileged Pointer Masking)
  - Smnpm (Machine-Mode Non-Privileged Pointer Masking)
  - Smmpm (Machine-Mode Pointer Masking)
  - Sspm (Supervisor Pointer Masking Availability)
  - Smstateen (Machine-Level State Enable)
  - H (Hypervisor Extension)
  - Sha (Augmented Hypervisor Extension)
  - Shcounterenw (Writable hcounteren)
  - Shgatpa (hgatp SvNNx4 Mode Support)
  - Shtvala (htval Written on Traps)
  - Shvsatpa (vsatp SvNN Mode Support)
  - Shvstvala (vstval Written on Traps)
  - Shvstvecd (vstvec Direct Mode)
  - Svpbmt (Page-Based Memory Types)
  - Svinval (Fine-Grained TLB Invalidation)
  - Svnapot ("NAPOT Translation" Continuity)
  - Svvptc (Previous Valid Translations Can Be Used)
  - Zba/Zbb/Zbc/Zbs (Bit Manipulations)
  - Zbkb/Zbkc/Zbkx (Scalar Cryptography Bit Manipulations)
  - Zknd/Zkne (AES Encryption/Decryption)
  - Zknh (SHA-256/SHA-512 Hash)
  - Zksed (SM4 Block Cipher)
  - Zksh (SM3 Hash)
  - Zk/Zkn/Zks (Scalar Cryptography Bundles)
  - Zca/Zcb (Compressed sub-extensions)
  - Zacas (Atomic Compare-And-Swap)
  - Zaamo (Atomic Memory Operations)
  - Zalrsc (Load-Reserved/Store-Conditional)
  - Zabha (8-bit / 16-bit Atomic Instructions)
  - Zawrs (Wait-on-Reservation-Set)
  - Zfa (Additional Floating-Point Instructions)
  - Zfh (Half-Precision Floating-Point)
  - Zfhmin (Half-Precision Float Minimal)
  - Zfbfmin (BFloat16 Minimal)
  - V (Vector Extension 1.0, configurable, enabled by default)
  - Zvbb (Vector Bit-manipulation for Cryptography)
  - Zvbc (Vector Carry-less Multiply)
  - Zvfh (Vector Half-Precision Floating-Point)
  - Zvfhmin (Vector Half-Precision Float Minimal)
  - Zvfbfmin (Vector BFloat16 Conversion Minimal)
  - Zvfbfwma (Vector BFloat16 Widening Multiply-Accumulate)
  - Zvkg (Vector GHASH for Cryptography)
  - Zvkb (Vector Cryptography Bit-manipulation)
  - Zvkned (Vector AES Encryption/Decryption)
  - Zvknha (Vector SHA-256)
  - Zvknhb (Vector SHA-256/SHA-512)
  - Zvksed (Vector SM4 Encryption/Decryption)
  - Zvksh (Vector SM3 Hash Function)
  - Zvkn/Zvknc/Zvkng (Vector NIST Crypto Bundles)
  - Zvks/Zvksc/Zvksg (Vector ShangMi Crypto Bundles)
  - Zvkt (Vector Data-Independent Execution Latency)
  - Zve32f/Zve32x/Zve64f/Zve64d/Zve64x (Vector Sub-extensions)
  - Zicntr (Base Counters and Timers)
  - Zihpm (Hardware Performance Counters)
  - Zkt (Data-Independent Execution Latency)
  - Zimop (May-Be-Operations)
  - Zcmop (Compressed May-Be-Operations)
  - Ztso (Total Store Ordering)
  - Zama16b (Misaligned Atomics 16-byte Guarantee)
  - Zicfilp (Landing Pad — Forward-Edge Control-Flow Integrity)
  - Zicfiss (Shadow Stack — Backward-Edge Control-Flow Integrity)
  - Zihintpause (Pause Hint)
  - Zihintntl (Non-Temporal Locality Hints)
- Multi-core SMP support
- Emulated peripherals
  - ACLINT
  - PLIC when AIA is not enabled (default), otherwise APLIC and IMSIC if AIA is enabled
  - AIA (Advanced Interrupt Architecture) support with APLIC and IMSIC devices, including VS-mode guest interrupt file support and AIA iprio support (interrupt priority)
  - UART NS16550A
  - SysCon   
  - VirtIO MMIO with following devices support
    - Block
    - Network
    - Random/Entropy
    - 9P filesystem
    - Filesystem (virtio-fs, FUSE-based host directory sharing)
    - Keyboard
    - Mouse
    - Sound
      - VirtIO Sound (default)
      - FM801 (Ensoniq PCI sound card, with PCM and  OPL3 support, if SoundMode=FM801, but currently with some timing dropout issues, so CMI8738 is recommended instead if OPL3 is needed, otherwise just use VirtIO Sound which works fine and has better performance and lower latency than all hardware-emulated sound options)
      - CMI8738 (C-Media PCI sound card, ring-buffer DMA with PCM and OPL3 support, if SoundMode=CMI8738)
      - HDA (Intel High Definition Audio, it is supported by the most operating systems, if SoundMode=HDA)
    - GPU (2D only, no 3D/virgl support yet)
    - Socket (vsock) — host-guest socket communication with stream and seqpacket support
    - RTC (if RTCMode=VirtIO) — real-time clock with UTC, TAI and monotonic clocks (nanosecond precision)
    - Crypto — virtual cryptographic accelerator with CIPHER, HASH, MAC and AEAD services (VirtIO 1.2 Device ID 20)
  - Display mode support with three selectable backends:
    - SimpleFB — custom MMIO framebuffer (default, for baremetal and simple guests)
    - VirtIO GPU — standard VirtIO 2D GPU with EDID support (for Linux with virtio-gpu driver)
      - This is the recommended display mode for Linux guests, as it offers better performance and compatibility than SimpleFB. The guest OS updates the framebuffer via VirtIO and marks it as dirty, so the host only refreshes the output when the content has actually changed, whereas SimpleFB requires polling the entire framebuffer every frame, which is very inefficient for Linux desktop environments with compositing and frequent screen updates.
    - Bochs VBE — PCI VGA adapter with VBE DISPI registers (for Linux with bochs-drm driver)
    - Cirrus Logic GD 5446 — PCI VGA adapter compatible with QEMU cirrus driver (for Linux with cirrus DRM driver)
  - Framebuffer support
  - Shared memory device for host-guest shared memory communication with doorbell IRQ support
  - PS/2 keyboard and mouse
  - Raw keyboard input with scancode bit-array (for more direct input per polling) 
  - DS1742 real-time clock (read-only, no write support)
  - Goldfish RTC (default, with interrupt support)
  - DS1307 I2C RTC (via I2C bus, if RTCMode=DS1307)
  - VirtIO RTC (VirtIO 1.4 Device ID 17, with UTC/TAI/Monotonic clocks)
  - PCIe Bus
    - NVMe SSD
    - IVSHMEM (Inter-VM Shared Memory) device for host-guest shared memory communication with doorbell interrupts
    - Bochs VBE VGA adapter (if DisplayMode=BochsVBE)
    - Cirrus Logic GD 5446 VGA adapter (if DisplayMode=Cirrus)
    - FM801 PCI audio (if SoundMode=FM801)
    - CMI8738 PCI audio (if SoundMode=CMI8738)
  - I2C bus with two selectable controller modes:
    - OpenCores I2C (opencores,i2c-ocores) — classic register-based I2C controller
    - Synopsys DesignWare I2C (snps,designware-i2c) — default, compatible with Linux i2c-designware driver
    - Attached devices:
      - DS1307 RTC (if RTCMode=DS1307)
      - HID keyboard (planned, currently disabled)
- Full MMU support with Sv39, Sv48 and Sv57 page table modes, including support for Svnapot and Svadu extensions
- Snapshot support (WIP and untested so far)
- Disassembler
  - RV64GCV instruction set support
  - Vector (V) extension instruction support  
  - Supports disassembling code with or without compressed instructions
  - Supports disassembling code with or without floating-point instructions
  - Provides human-readable assembly code output
- Debugger
  - Internal debugger
    - Command line interface
    - Debugger GUI backend API support
    - Breakpoint support
    - Memory and register inspection/modification
    - Step, Continue, Pause execution control
    - Reboot, Reset, PowerOff/Shutdown control
  - GDB remote debugging support (partially implemented)
    - Own GDB server implementation
  - Multiple debugger client support 
    - GDB, internal CLI, custom GUI backends, all simultaneously at the same time
- ELF loader
- Linux kernel boot support
- Untested support for other OS images (FreeBSD, NetBSD, OpenBSD, Haiku, etc.), may require additional fixes or tweaks
- Device Tree Blob (DTB) support
- Initrd support
- Command line support for the guest OS
- Simple test suite with various test cases for different parts of the emulator
- Tracing JIT compiler
  - Integrated into the interpreter, traces hot paths and compiles native code on-the-fly
  - Block linking, inline TLB lookups, and AUIPC/JALR optimization
  - x86-64 backend (fully functional)
  - AArch64 backend (stub, not yet implemented)
  - RISC-V 64 backend (stub, not yet implemented)
  - Integer and floating-point JIT support (FPU JIT optional, separately toggleable) including FMA instructions 
  - Automatic cache management with block invalidation on page changes
  - Partial vector instruction support (work in progress), non-SIMDizable cases fall back to the interpreter and may even be slower than pure interpretation due to JIT overhead. Full RVV JIT coverage may never be complete due to the complexity of variable-length vectors and the wide range of RVV operations. A fixed-width Packed-SIMD extension (like the proposed P extension) with traditional fixed-size SIMD registers would be significantly easier to map to host SIMD (SSE/AVX, NEON) in the JIT than RVV's variable-length vector model.
- Cross-platform (Windows, Linux, macOS)
- Written in Object Pascal (Free Pascal / Lazarus / Delphi)

## Why 64-bit only?

The decision to support only 64-bit RISC-V (RV64GCV) is primarily driven by the need for a modern architecture that can efficiently handle current and future workloads. 64-bit architectures provide several advantages over their 32-bit counterparts, including:

1. **Larger Address Space**: 64-bit systems can address significantly more memory than 32-bit systems, allowing for more extensive and complex applications.

2. **Improved Performance**: 64-bit processors can handle more data per clock cycle, leading to better performance for compute-intensive tasks.

3. **Future-Proofing**: As software and workloads evolve, the demand for 64-bit processing power will only increase. Supporting 64-bit from the outset ensures that the emulator can accommodate future developments.

4. **Compatibility with Modern Software**: Most modern operating systems and applications are designed with 64-bit architectures in mind, making it essential for the emulator to support this architecture for compatibility reasons.

And support for 32-bit RISC-V is virtually nonexistent outside of source-based distros (Gentoo, Buildroot, Yocto, etc.), microcontrollers, strange embedded systems and some hobbyist projects. Most mainstream Linux distributions, other operating systems and software projects have moved to 64-bit as the standard, making it more practical to focus only on 64-bit support. 32-bit support would require additional development and maintenance effort, which may not be justified given the limited use cases and demand for 32-bit RISC-V. So, it is 64-bit only, and it will remain that way. The same applies to 128-bit RISC-V, which is not supported at all, since there is no real-world implementation or use case for it at this time.

## Why Little-Endian only? Why not Big-Endian or Mixed-Endian?

The decision to support only Little-Endian mode in the PasRISCV emulator is based on several practical considerations:

1. **Prevalence of Little-Endian**: Little-Endian is the most commonly used endianness in modern computing systems, including x86 and modern ARM architectures. By focusing on Little-Endian, the emulator aligns with the majority of existing software and hardware, ensuring better compatibility and ease of use. And most all RISC-V systems in the wild are also Little-Endian. And the RISC-V specification itself defaults to Little-Endian, with Big-Endian support being not specified and rarely implemented officially.

2. **Simplicity and Maintainability**: Supporting multiple endianness modes (Little-Endian, Big-Endian, and Mixed-Endian) would significantly increase the complexity of the emulator's design and implementation. This added complexity could lead to more bugs, increased development time, and greater maintenance challenges. By limiting the scope to Little-Endian, the development process becomes more straightforward and manageable.

3. **Target Audience**: The primary users of the PasRISCV emulator are likely to be developers and enthusiasts who are already familiar with Little-Endian systems. By catering to this audience, the emulator can provide a more focused and optimized experience.

4. **Performance Considerations**: Emulating multiple endianness modes could introduce performance overhead due to the need for additional checks and conversions during memory access operations. By standardizing on Little-Endian, the emulator can optimize performance for the most common use cases.

5. **Low Byte-Swapping Costs**: Modern compilers and processors are highly optimized for handling byte-swapping operations when necessary. This means that even if a user needs to work with Big-Endian data, the performance impact of converting between endianness is minimal in most scenarios. PasRISCV supports the Zbb extension, which includes bit manipulation instructions that can facilitate efficient byte-swapping just in a single instruction when needed, for example for network protocols (network byte order) or older file formats that used still Big-Endian.

6. **Big-Endian Is Dead**: There are very few use cases for Big-Endian systems today, and they are mostly limited to legacy systems or specific niche applications. The demand for Big-Endian support is minimal, making it less justifiable to invest resources in its implementation. Big-Endian lives on mostly in some network protocols (network byte order) and some older file formats, but even there, its use is declining as more systems adopt Little-Endian.

7. **Mixed-Endian Complexity**: Mixed-Endian systems, which use different endianness for different data types or structures, are even more complex to implement and maintain. The rarity of Mixed-Endian systems in practical applications further diminishes the need for support in the emulator.

Overall, the decision to support only Little-Endian mode in the PasRISCV emulator is a strategic choice that balances compatibility, simplicity, performance, and user needs. While Big-Endian and Mixed-Endian modes have their use cases, the benefits of focusing on Little-Endian outweigh the potential advantages of supporting multiple endianness modes in this context.

## Usage

See [pasriscvemu](https://github.com/BeRo1985/pasriscvemu) PasVulkan project for an emulator frontend that uses this library.

## Compile-Time Feature Flags

Some features are controlled by compile-time `{$define}` directives at the top of `src/PasRISCV.pas`. These flags exist because even when a feature is logically inactive at runtime, having the conditional checks compiled in can still impose a measurable performance overhead in hot paths (e.g. every instruction's cycle counter update in the JIT or interpreter).

| Define | Default | Description |
|--------|---------|-------------|
| `PasRISCVSmcntrpmf` | enabled | Smcntrpmf — Counter Privilege-Mode Filtering. When enabled, the cycle counter can be inhibited per-privilege-mode via `mcyclecfg`/`minstretcfg` CSRs. The JIT uses a branchless mask (`CycleIncrementMask`) to avoid branches in hot paths, but the extra load+AND+memory-add sequence has a small cost even when counting is not inhibited. Disable by commenting out `{$define PasRISCVSmcntrpmf}` if Smcntrpmf guest support is not required. |
| `PasRISCVSmdbltrp` | disabled | Smdbltrp — Machine-Mode Double Trap. When enabled, trapping to M-mode while `mstatus.MDT=1` triggers a double-trap: the hart is redirected to the RNMI handler (if `mnstatus.NMIE=1`) or halted. `mstatus.MDT` is set on every M-mode trap entry and cleared by MRET. Although the checks are only reached on the (rare) trap path, the MDT bit participates in the `mstatus` WARL mask even when inactive, which subtly changes CSR write behaviour. Enable by uncommenting `{$define PasRISCVSmdbltrp}`. |
| `PasRISCVSsdbltrp` | disabled | Ssdbltrp — Supervisor-Mode Double Trap. Requires `PasRISCVSmdbltrp`. When enabled, two independent double-trap mechanisms are active: **(1) HS-mode:** if `menvcfg.DTE=1` and `mstatus.SDT=1`, a trap to HS-mode escalates to M-mode as a synchronous cause-16 exception (`mcause=16`, `mtval2=original scause`). **(2) VS-mode:** if `henvcfg.DTE=1` and `vsstatus.SDT=1`, a trap to VS-mode escalates to HS-mode as a synchronous cause-16 exception (`scause=16`, `htval=original vscause`). Both SDT bits are set on every respective trap entry (when the corresponding DTE=1) and cleared by the matching SRET. Writing SDT=1 to `mstatus`/`vsstatus` forces the corresponding SIE=0. Enable by uncommenting `{$define PasRISCVSsdbltrp}`. |

## ISA Extension Notes

### Ssqosid (Quality-of-Service Identifiers)

**What it does in real hardware:** 

- Every memory and cache request issued by a hart carries two identifiers propagated from the `srmcfg` CSR
- The RCID (Resource Control ID, bits 11:0) and the MCID (Monitoring Counter ID, bits 27:16).
- Shared resource controllers such as LLC partitioners, memory bandwidth limiters, and performance monitors use these IDs to enforce per-workload resource allocation and to attribute resource-usage statistics.
- The OS scheduler writes `srmcfg` on every context switch to assign the incoming task's QoS class and monitoring slot.

**What this means for the emulator:** 

- PasRISCV does not emulate any QoS-capable resource controllers, so RCID and MCID have no effect on emulator behaviour.
- The `srmcfg` CSR (`$181`) is fully implemented as a read/write register with correct WPRI masking (only bits 11:0 and 27:16 are writable), ensuring that guest software (including the Linux CBQRI / Ssqosid kernel driver) can discover and use the extension without taking illegal-instruction traps and without observing any data corruption on reads.

### Smdbltrp / Ssdbltrp (Machine / Supervisor Double Trap)

**What they do in real hardware:** 

These extensions (ratified August 2024) add hardware-enforced detection of nested trap conditions that would otherwise silently corrupt machine state.

- **Smdbltrp** introduces `mstatus.MDT` (bit 42). Hardware sets MDT=1 on every M-mode trap entry. If a second trap to M-mode occurs while MDT is already 1, the hart detects a *machine double trap*: if `mnstatus.NMIE=1` it is redirected to the RNMI handler to allow controlled recovery; otherwise the hart enters a non-recoverable error state. MRET clears MDT. On reset, MDT is initialised to 1 (the hart starts as though it just took a trap) so that any early boot fault is caught.
- **Ssdbltrp** introduces `mstatus.SDT` (bit 24), `vsstatus.SDT` (bit 24), `menvcfg.DTE` (bit 24), and `henvcfg.DTE` (bit 24). Two independent double-trap mechanisms apply:
  - *HS-mode double trap:* When M-mode sets `menvcfg.DTE=1`, hardware sets `mstatus.SDT=1` on every HS-mode trap entry. If a second trap to HS-mode occurs while SDT is already 1, the fault escalates to M-mode as a synchronous exception with `mcause=16`, `mtval2` holding the original would-be `scause`. SRET and MRET clear `mstatus.SDT`.
  - *VS-mode double trap:* When the hypervisor sets `henvcfg.DTE=1`, hardware sets `vsstatus.SDT=1` on every VS-mode trap entry. If a second trap to VS-mode occurs while `vsstatus.SDT` is already 1, the fault escalates to HS-mode as a synchronous exception with `scause=16`, `htval` holding the original would-be `vscause`. VS-mode SRET clears `vsstatus.SDT`. In both cases, writing SDT=1 to the respective status CSR also forces the corresponding SIE bit to 0.

**What this means for the emulator:** 

- Both HS-mode and VS-mode double-trap detection are fully implemented:
  - `mstatus.MDT`, `mstatus.SDT`, `vsstatus.SDT`, `menvcfg.DTE`, and `henvcfg.DTE` are readable and writable WARL fields
  - Double-trap detection runs on every trap entry
  - The RNMI redirect, M-mode escalation, and HS-mode escalation paths are all implemented. 
- Because the checks sit on the (relatively rare) trap entry and exit paths rather than in the per-instruction hot loop, the runtime overhead is negligible.
  - Nevertheless, the extensions change the `mstatus`/`vsstatus` WARL mask even when logically inactive, so they are guarded behind compile-time `{$define}` flags (`PasRISCVSmdbltrp` / `PasRISCVSsdbltrp`) to allow complete exclusion when not needed.

### Smepmp (Enhanced Physical Memory Protection)

**What it does in real hardware:**

Smepmp (ratified 2021) extends the baseline PMP with three new `mseccfg` control bits that tighten M-mode memory isolation:

- **RLMBE** (Rule Locking Bypass Enable): when 0, locked PMP entries apply to M-mode as well, so M-mode code cannot bypass its own locked PMP rules. Provides a one-way ratchet: once RLMBE is cleared to 0, M-mode can never re-enable bypass without a reset.
- **MMWP** (Machine-Mode Whitelist Policy): when 1, any M-mode access that does not match a PMP entry is denied (whitelist semantics), rather than allowed (default blacklist semantics). Forces explicit PMP coverage of all M-mode memory.
- **MML** (Machine-Mode Lockdown): the most complex bit. When 1, it completely redefines the permission-encoding of all PMP entries: entries previously interpreted as S/U-mode rules are reinterpreted as M-mode rules (or shared rules), and the permission combinations that were formerly reserved become meaningful. This allows simultaneously expressing M-mode-only, S/U-mode-only, and shared read-only regions in the same PMP table. Once set, MML cannot be cleared without a reset.

OpenSBI >= v1.3 uses Smepmp to enforce M-mode memory isolation by clearing RLMBE and optionally setting MMWP, hardening the security boundary between the firmware and the OS.

**What this means for the emulator:**

- The `mseccfg` CSR (`$747`) is implemented and writable with correct WARL masking.
- The USEED and SSEED bits (entropy source seeding permission) are fully functional.
- The MLPE bit (M-mode Landing Pad Enable, from Zicfilp) is functional when `{$define Zicfilp}` is active.
- **RLMBE, MMWP, and MML are accepted as writes but not enforced**: all three bits can be set and read back correctly, but the emulator does not change its memory-access permission logic based on them.

This is sufficient for a Linux guest: the guest OS never touches `mseccfg` directly. OpenSBI will attempt to use Smepmp and will not receive a trap, but the additional memory isolation it would normally provide is not active. Full enforcement is not required for functional correctness of any guest OS workload.

## Documentation

See the `docs` directory for more information.

## Related connected repositories

- [PasRISCV Third-Party Software Repository](https://github.com/BeRo1985/pasriscv_software) - This repository contains third-party software, including test cases, guest Linux system build scripts, and other related assets, for the PasRISCV Emulator — a RV64GCV/RVA23 RISC-V emulator developed in Object Pascal. Needed for the test suite and other related assets.
- [PasVulkan](https://github.com/BeRo1985/pasvulkan) - PasVulkan game engine and Vulkan API bindings for Object Pascal.
- [pasriscemu](https://github.com/BeRo1985/pasriscvemu) - PasRISCV Emulator frontend using PasVulkan.

## License

This project is released under zlib license.
