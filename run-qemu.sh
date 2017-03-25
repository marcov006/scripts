#!/bin/bash

BR=/work/buildroot

qemu-system-x86_64 -M pc -kernel $BR/output/images/bzImage -drive file=$BR/output/images/rootfs.ext2,if=virtio,format=raw -append 'console=ttyS0 root=/dev/vda' -net nic,model=virtio -net user -nographic
