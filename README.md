# endbasic-hermit

Bare metal [EndBASIC](https://endbasic.dev) using [Hermit for Rust](https://github.com/hermit-os/hermit-rs).


## Requirements

* [`rustup`](https://www.rust-lang.org/tools/install)
* [QEMU](https://www.qemu.org/)


## Usage

### Install the Rust Standard Library for Hermit

See [rust-std-hermit](https://github.com/hermit-os/rust-std-hermit).

Note that rust-std-hermit is not available for the `stable` toolchain channel but for specific channels of stable Rust versions.
See [rust-toolchain.toml](rust-toolchain.toml).

### Building EndBASIC-Hermit

```
$ cargo build --target aarch64-unknown-hermit --release
```

### Running EndBASIC-Hermit in QEMU

```
$ ./start.sh
```

### Running EndBASIC-Hermit in a Raspberry Pi 4b

#### Supported devices

- GIC-400 interrupt controller.
- Pl011 serial console.
- VideoCore raw framebuffer with HDMI output.

#### Requirements

- A Raspberry Pi 4b or a Raspberry Pi 400.
- A USB to UART TTL cable.
- An SD card.

### Instructions

- Flash Raspbian to the SD card.
- Copy `prebuilts/kernel8.img` to the first partition of the SD card, overwritting the existing file.
- Copy `target/aarch64-unknown-hermit/release/endbasic-hermit` to the first partition of the SD card.
- Edit `config.txt` in the first partition of the SD card to add the following lines:
```
enable_uart=1
arm_64bit=1
device_tree_address=0x08000000
ramfsfile=endbasic-hermit
ramfsaddr=0x09000000
```
- Connect the USB to UART TTL cable to both the Raspberry Pi 4b and a computer, and open a terminal emulator on the latter.
- Insert the SD card in the Raspberry Pi 4b, connect the HDMI output to a monitor, and power on the Raspberry Pi 4b.

### Notes

As USB HID is not yet supported, keyboard input must be provided through the serial console.