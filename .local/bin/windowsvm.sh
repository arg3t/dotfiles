#!/bin/sh

exec qemu-system-x86_64 -enable-kvm \
        -cpu host \
        -drive file=/home/yigit/.local/share/Virtual/WindowsVM.img,if=virtio \
        -net nic -net user,hostname=windowsvm \
        -m 4G \
        -smp 6 \
        -monitor stdio \
        -name "Windows" \
        "$@"


