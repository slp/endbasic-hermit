SYSTEM=`uname -s`
DISPLAY=gtk
if [ "$SYSTEM" == "Darwin" ]; then
	DISPLAY=cocoa
fi

qemu-system-aarch64 -machine raspi4b -cpu cortex-a76 -smp 4 -m 2g -display $DISPLAY -serial stdio -dtb prebuilts/virt.dtb -kernel prebuilts/kernel8.img -device guest-loader,addr=0x9000000,initrd=target/aarch64-unknown-hermit/release/endbasic-hermit
