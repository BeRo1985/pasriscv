
# Base devices

These following devices are the base devices that are almost always present in a RISC-V system. They are the minimum set of devices that are 
required to boot a RISC-V system.

| What                  | Where     | Size      | IRQ(s)                    | Description                                                                          |
|-----------------------|-----------|-----------|---------------------------|--------------------------------------------------------------------------------------|
| DS1742                | $00101000 | $8        |                           | Real-time clock                                                                      |
| ACLINT                | $02000000 | $10000    |                           | Core Local Interruptor                                                               |
| PLIC                  | $0c000000 | $208000   |                           | Platform Level Interrupt Controller (if no AIA)                                      |
| APLIC                 | $0cfffffc | $0004     |                           | Advanced Platform Level Interrupt Controller (internal ghost device if AIA)          |
| APLIC-M               | $0c000000 | $4000     |                           | Advanced Platform Level Interrupt Controller for Machine mode (if AIA)               |
| APLIC-S               | $0d000000 | $4000     |                           | Advanced Platform Level Interrupt Controller for Supervisor mode (if AIA)            |
| UART                  | $10000000 | $100      | $0a                       | Universal Asynchronous Receiver/Transmitter                                          | 
| SYSCON                | $11100000 | $1000     |                           | System Controller (Reset, Power off, etc.)                                           |
| IMSIC-M               | $24000000 | #HART<<12 |                           | Interrupt Message Signaled Interrupt Controller (IMSIC) for Machine mode (if AIA)    |
| IMSIC-S               | $28000000 | #HART<<12 |                           | Interrupt Message Signaled Interrupt Controller (IMSIC) for Supervisor mode (if AIA) |

# HID devices

These devices are the Human Interface Devices (HID) that are used to interact with the system. 

| What                  | Where     | Size      | IRQ(s)                    | Description                                 |
|-----------------------|-----------|-----------|---------------------------|---------------------------------------------|
| RAW KEYBOARD          | $10008000 | $1000     |                           | Raw keyboard input with scancode bit-array  |
| PS/2 KEYBOARD         | $10010000 | $8        | $05                       | PS/2 keyboard input                         |
| PS/2 MOUSE            | $10011000 | $8        | $06                       | PS/2 mouse input                            |

Once the operating system initializes the VirtIO HID devices, the PS/2 HID devices are no longer fed with input data to avoid duplicating input events.

The raw keyboard device is a simple device that provides a bit array of scancodes. It can be used in conjunction with games specially tweaked for the emulator or other applications that work better with raw scan codes.

# I2C devices

The emulator includes an I2C bus with two selectable controller modes, configurable via `Configuration.I2CMode`. The I2C bus is activated automatically when `RTCMode=DS1307`.

| Mode       | Device                  | Size   | Compatible string          | Linux driver              | Description                                                    |
|------------|-------------------------|--------|----------------------------|---------------------------|----------------------------------------------------------------|
| OpenCores  | TOpenCoresI2CDevice     | $14    | opencores,i2c-ocores       | i2c-ocores                | Classic register-based I2C controller (CLKLO/HI, CTR, TXR/RXR, CR/SR) |
| DesignWare | TDesignWareI2CDevice    | $100   | snps,designware-i2c        | i2c-designware-platform   | Synopsys DesignWare I2C controller with RX/TX FIFOs (16 entries each), interrupt-driven, COMP_TYPE/VERSION/PARAM_1 identification registers. Default mode. |

Both controllers share the same base address ($10020000) and IRQ ($0d).

| What                  | Where     | Size      | IRQ(s)                    | Description                                 |
|-----------------------|-----------|-----------|---------------------------|---------------------------------------------|
| I2C                   | $10020000 | $14/$100  | $0d                       | I2C controller (size depends on mode)       |

# VirtIO devices

These devices are the VirtIO devices that are used to connect to the system. They are partly required for the system to boot, but not all of them
are required. The VirtIO devices are used to provide a standard interface for devices for virtual machines.

| What                  | Where     | Size      | IRQ(s)                    | Description                                 |
|-----------------------|-----------|-----------|---------------------------|---------------------------------------------|
| VIRTIO BLOCK          | $10050000 | $1000     | $10                       | VirtIO block device                         |
| VIRTIO INPUT KEYBOARD | $10051000 | $1000     | $11                       | VirtIO keyboard input                       |
| VIRTIO INPUT MOUSE    | $10052000 | $1000     | $12                       | VirtIO mouse input                          |
| VIRTIO INPUT TOUCH    | $10053000 | $1000     | $13                       | VirtIO touch input (planned)                |
| VIRTIO SOUND          | $10054000 | $1000     | $14                       | VirtIO sound device                         |
| VIRTIO 9P             | $10055000 | $1000     | $15                       | VirtIO 9P device                            |
| VIRTIO NET            | $10056000 | $1000     | $16                       | VirtIO network device                       |
| VIRTIO RNG            | $10057000 | $1000     | $17                       | VirtIO random number generator              |
| VIRTIO GPU            | $10058000 | $1000     | $18                       | VirtIO GPU device (if DisplayMode=VirtIOGPU) |
| VIRTIO VSOCK          | $10059000 | $1000     | $19                       | VirtIO socket device                        |

For each VirtIO device, the MMIO region size is $1000. For the VirtIO GPU device, the guest OS allocates its own frame buffer memory ranges, so $1000 as MMIO region size remains valid for the device registers in this case.

# Display modes

The emulator supports three display modes, selectable via `Configuration.DisplayMode`:

| Mode       | Device                  | Type       | Linux driver   | Description                                                                                           |
|------------|-------------------------|------------|----------------|-------------------------------------------------------------------------------------------------------|
| SimpleFB   | TSimpleFBDevice         | MMIO       | simplefb       | Custom framebuffer at $28000000, uses a simple memory-mapped interface with control registers. Default mode, suitable for baremetal and simple guest software. |
| VirtIOGPU  | TVirtIOGPUDevice        | VirtIO MMIO| virtio-gpu     | VirtIO GPU (2D only, no 3D/virgl). Guest allocates resources, attaches backing memory, transfers pixel data and flushes to host framebuffer. Supports EDID. |
| BochsVBE   | TBochsVBEDevice         | PCIe       | bochs-drm      | Bochs VBE VGA adapter on PCIe bus (vendor $1234, device $1111). 16MB linear framebuffer (BAR0) with VBE DISPI registers (BAR2) for mode setting. |
| Cirrus     | TCirrusDevice           | PCIe       | cirrus (drm)   | Cirrus Logic GD 5446 VGA adapter on PCIe bus (vendor $1013, device $00b8). 4MB linear framebuffer (BAR0) with VGA register MMIO (BAR2) for mode setting. Subsystem IDs match QEMU ($1af4:$1100) for Linux cirrus-qemu driver compatibility. |

All three modes write their output to the shared `TFrameBufferDevice` pixel buffer, which the host frontend reads for rendering. The frontend code does not need to change between display modes.

# Shared Memory device

The shared memory device provides a simple flat memory-mapped region for zero-copy host-guest communication. It is declared as a `reserved-memory` node in the device tree with `no-map` to prevent the kernel from using it as regular RAM. The device includes a small register area (first 64 bytes) for control and signaling, followed by the data region.

| What                  | Where     | Size      | IRQ(s)                    | Description                                 |
|-----------------------|-----------|-----------|---------------------------|---------------------------------------------|
| SHARED MEMORY         | $2f000000 | $100000   | $1a                       | Shared memory with doorbell IRQ             |

Register layout (offsets from base address):

| Offset | Size    | Access       | Description                                                  |
|--------|---------|--------------|--------------------------------------------------------------|
| $00    | 4 bytes | Guest: Write | Doorbell — writing triggers a callback on the host side      |
| $04    | 4 bytes | Guest: Read  | Host flags — set by the host, readable by the guest          |
| $08    | 4 bytes | Guest: R/W   | Guest flags — set by the guest, readable by the host         |
| $0C    | 4 bytes | Guest: Read  | Data size — size of the shared data region in bytes          |
| $10    | 4 bytes | Guest: Read  | IRQ status — bitmask of pending interrupt reasons            |
| $14    | 4 bytes | Guest: Write | IRQ acknowledge — write bits to clear corresponding IRQ      |
| $40+   | varies  | Guest: R/W   | Shared memory data region                                    |

# PCIe devices

These devices are the Peripheral Component Interconnect Express (PCIe) devices that are used to connect to the system. 

| What                  | Where     | Size      | IRQ(s)                    | Description                                 |
|-----------------------|-----------|-----------|---------------------------|---------------------------------------------|
| PCIe controller base  | $30000000 | $10000000 | $01 - $04 (cross-wired)   | PCIe controller base MMIO                   |
| PCIe I/O              | $03000000 | $00010000 |                           | PCIe I/O                                    |
| PCIe BAR memory range | $40000000 | $40000000 |                           | PCIe BAR memory range                       |

# PCIe bus devices

These devices are the PCIe bus devices that are used to connect to the system.

| Bus  | Device | Function | Class ID | Vendor ID | Device ID | Description                                                 |
|------|--------|----------|----------|-----------|-----------|-------------------------------------------------------------|
| $00  | $00    | $00      | $0600    | $f15e     | $0000     | PCIe controller (host bridge)                               |
| $00  | $01    | $00      | $0108    | $1aad     | $a809     | Non-Volatile Memory Controller (NVMe) / NVMe SSD controller |
| $00  | $03    | $00      | $0300    | $1234     | $1111     | Bochs VBE VGA compatible controller (if DisplayMode=BochsVBE) |
| $00  | $04    | $00      | $0300    | $1013     | $00b8     | Cirrus Logic GD 5446 VGA controller (if DisplayMode=Cirrus)   |

# Boot Trampoline and Device Tree Blob Memory

The memory region for the boot trampoline and the Device Tree Blob (DTB) is a dedicated 64KiB segment starting at $00000000. This memory serves two primary purposes:

1. **Boot Trampoline Code**: The boot trampoline code initializes essential CPU components, including CPU registers and the stack pointer. After initialization, it transfers control to the firmware's entry point. In the future, this code will be removed, and the CPU emulation will directly handle the initialization of registers and the stack pointer.

2. **Device Tree Blob (DTB)**: The DTB provides a structured description of the system's hardware configuration to the operating system. It is passed to the operating system by the firmware and includes details such as CPU cores, memory, and device mappings.

# System Memory

The system memory begins at $80000000 and its size is dynamically determined based on the system configuration. It is the primary memory space and serves multiple purposes:

- **Operating System**: The system memory stores the kernel, essential services, and system libraries required for operation.
- **Applications and Data**: User applications, processes, and associated data are loaded and managed here.
- **Firmware and DTB**: The firmware and a copy of the Device Tree Blob are also stored in system memory, ensuring accessibility during boot and runtime.

This dynamic memory allocation ensures flexibility and scalability, adapting to the needs of different system configurations.

