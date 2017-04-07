#!/bin/bash

set +eux

BR=/work/buildroot
DEFCONFIG=qemu_x86_64_defconfig

echo "Buildroot configuration: $DEFCONFIG"
cd $BR
make $DEFCONFIG

echo "  - console on ttyS0"
sed -i 's/tty1/ttyS0/' .config

echo "  - enable BR2_PACKAGE_LOCAL"
echo "BR2_PACKAGE_LOCAL=y" >> .config

echo "  - LINUX overriden"
echo "LINUX_OVERRIDE_SRCDIR=../linux" > local.mk

echo "  - LOCAL overriden"
echo "LOCAL_OVERRIDE_SRCDIR=../eudyptula/task20" >> local.mk

echo "Making Buildroot"
make
