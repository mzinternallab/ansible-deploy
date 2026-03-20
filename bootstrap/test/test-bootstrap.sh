#!/usr/bin/env bash
qemu-system-x86_64 \
  -name 'rocky8' \
  -smp cpus=4,sockets=1,cores=4 \
  -m 4096 \
  -nodefaults \
  -drive if=pflash,format=raw,unit=0,readonly=true,file=OVMF_CODE.fd \
  -drive if=pflash,format=raw,unit=1,file=OVMF_VARS.fd \
  -drive if=virtio,media=disk,index=0,file=test.qcow2 \
  -drive if=none,id=usbks,format=raw,file=test-usb.img \
  -cdrom rocky85-boot.iso \
  -vga std \
  -device nec-usb-xhci,id=xhci \
  -usbdevice tablet \
  -device usb-storage,bus=xhci.0,drive=usbks \
  -display vnc=:1
