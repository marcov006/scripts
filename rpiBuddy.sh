#!/bin/bash

set -eux

#SOURCE="$(pwd)"
SOURCE="/work"

declare -A remotes
remotes[u-boot]="git://git.denx.de/u-boot.git"
#remotes[rpi-tools]="git://github.com/raspberrypi/tools"
remotes[rpi-firmware]="git://github.com/raspberrypi/firmware.git"
remotes[buildroot]="https://github.com/buildroot/buildroot.git"
remotes[linux]="https://github.com/raspberrypi/linux"

RELEASE="2017-04-10"
RASPBIAN_URL="https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-'$RELEASE'/'$RELEASE'-raspbian-jessie-lite.zip"

HELP=false
RPI=2
UBOOT=false
LINUX=false
BUILDROOT=false
RASPBIAN=false
SDCARD=false
UPDATE=false
DEV=/dev/sdb
MNT=/mnt

while true; do
	case "${1:-unset}" in
		-h | --help) HELP=true; shift ;;
		-r | --rpi) RPI=$2; shift 2;;
		-u | --uboot) UBOOT=true; shift ;;
		-l | --linux) LINUX=true; shift ;;
		-b | --buildroot) BUILDROOT=true; shift ;;
		-R | --raspbian) RASPBIAN=true; shift ;;
		-s | --sdcard) SDCARD=true; shift ;;
		-U | --update) UPDATE=true; shift ;;
		-d | --dev) DEV=$2; shift 2;;
		*) break ;;
	esac
done

function help {
	cat <<EOF
NAME:
	$0 - Raspberry Pi helper

OPTIONS:
	--rpi: rpi revision [2|3] (default: $RPI)
	--uboot: build u-boot for raspberry pi (default: $UBOOT)
	--linux: build linux for raspberry pi (default: $LINUX)
	--buildroot: build buildroot for raspberry pi (default: $BUILDROOT)
	--raspbian: raspbian lite (default: $RASPBIAN)
	--sdcard: create a fresh SDCARD (default: $SDCARD)
	--update: update existing SDCARD (default: $UPDATE)
	--dev: SDCARD device (default: $DEV)
EOF
	exit 0
}

if $HELP; then
	help
fi

UBOOT_RPI_DEFCONFIG=rpi_"$RPI"_defconfig
BR_RPI_DEFCONFIG=raspberrypi"$RPI"_defconfig
LINUX_RPI_DEFCONFIG=bcm2709_defconfig

echo "Checking sources folder..."
for r in "${!remotes[@]}"; do
	if [ ! -d "$SOURCE"/"$r" ]; then
		echo "$SOURCE/"$r" does not exist... cloning a fresh repo";
		[ -d "$SOURCE" ] || mkdir -p "$SOURCE"
		cd "$SOURCE" && git clone "${remotes[$r]}"
		cd -
	else
		echo "$r found, skip"
		#update remote?
	fi
done

if $RASPBIAN; then
	echo "Downloading last raspbian image..."
	if [ ! -f "$SOURCE"/raspbian/"$RELEASE"-raspbian-jessie-lite.img ]; then
		echo "$SOURCE/raspbian does not exist... downloading latest rasbian image";
		[ -d "$SOURCE" ] || mkdir -p "$SOURCE"
		[ -d "$SOURCE"/raspbian ] || mkdir -p "$SOURCE"/raspbian
		cd "$SOURCE"/raspbian
		if [ ! -f "$SOURCE"/raspbian/"$RELEASE"-raspbian-jessie-lite.zip ]; then
			wget "$RASPBIAN_URL"
		fi
		unzip "$RELEASE"-raspbian-jessie-lite.zip
		cd -
	fi
fi

echo "Exporting arm cross-compiling tools...."
for pkg in gcc-arm-linux-gnueabi gcc-aarch64-linux-gnu; do
	dpkg -s $pkg 2>/dev/null >/dev/null || sudo apt-get -y install $pkg
done

if [ $RPI -eq 2 ];then
	export CROSS_COMPILE=arm-linux-gnueabi-
	#export CROSS_COMPILE="$SOURCE"/rpi-tools/arm-bcm2708/arm-bcm2708hardfp-linux-gnueabi/bin/arm-bcm2708hardfp-linux-gnueabi-
	#export CROSS_COMPILE="$SOURCE"/rpi-tools/arm-bcm2708/arm-bcm2708-linux-gnueabi/bin/arm-bcm2708-linux-gnueabi-
else
	export CROSS_COMPILE=aarch64-linux-gnu-
fi

if $UBOOT; then
	echo "Making u-boot:$UBOOT_RPI_DEFCONFIG...."
	cd "$SOURCE/u-boot"
	make clean
	make $UBOOT_RPI_DEFCONFIG
	make -j$(nproc)
fi

if $BUILDROOT; then
	echo "Making buildroot:$BR_RPI_DEFCONFIG...."
	cd "$SOURCE/buildroot"
	make $BR_RPI_DEFCONFIG
	make
fi

if $LINUX; then
	echo "Making linux:$LINUX_RPI_DEFCONFIG...."
	cd "$SOURCE/linux"
	KERNEL=kernel7
	make ARCH=arm $LINUX_RPI_DEFCONFIG
	make ARCH=arm $LINUX_RPI_DEFCONFIG -j$(nproc) zImage modules dtbs
fi

if $SDCARD; then
	if [ ! -e $DEV ] ; then
		echo "$DEV" does not exist, exit.
		exit 0
	fi

	if $RASPBIAN; then
		echo "Creating full SDCARD with raspbian lite"
		sudo dd bs=1M if="$SOURCE"/raspbian/"$RELEASE"-raspbian-jessie-lite.img of=$DEV
	else #$BUILDROOT
		echo "Creating full SDCARD with buildroot"
		sudo dd if="$SOURCE"/buildroot/output/images/sdcard.img of=$DEV
	fi
	sync
	echo SDCARD is ready, you can unplug it and try it on your Raspberry pi$RPI board!!!
fi

if $UPDATE; then
	if [ ! -e $DEV ] ; then
		echo "$DEV" does not exist, exit.
		exit 0
	fi
	if [ -e "$DEV"1 ] ; then
		DEV1="$DEV"1
		DEV2="$DEV"2
	elif [ -e "$DEV"p1 ] ; then
		DEV1="$DEV"p1
		DEV2="$DEV"p2
	else
		echo neither "$DEV"1 or "$DEV"p1 exist, exit.
		exit 0
	fi

	#we mount and update the SDCARD now.
	#we assume that the SDCARD is correctly formated
	sudo mkdir -p "$MNT"/fat
	sudo mkdir -p "$MNT"/ext4

	sudo mount "$DEV2" "$MNT"/ext4
	if $RASPBIAN; then
		sudo mount "$DEV1" "$MNT"/fat
	else #BUILRDOOT
		sudo mount -t msdos "$DEV1" "$MNT"/fat
	fi

	if $LINUX; then
		echo "Copying linux to SD-CARD (kernel, dtb, modules)"
		cd "$SOURCE"/linux
		sudo cp arch/arm/boot/zImage "$MNT"/fat/
		#update the config.txt
		sudo sed -i.bak '/kernel=/d' "$MNT"/fat/config.txt
		sudo sh -c "echo 'kernel=zImage' >> '$MNT'/fat/config.txt"
		sudo cp arch/arm/boot/dts/bcm*.dtb "$MNT"/fat/
		[ -d "$MNT"/fat/overlays ] || mkdir -p "$MNT"/fat/overlays
		sudo cp arch/arm/boot/dts/overlays/*.dtb* "$MNT"/fat/overlays/
		sudo cp arch/arm/boot/dts/overlays/README "$MNT"/fat/overlays/
		sudo make ARCH=arm INSTALL_MOD_PATH="$MNT"/ext4 modules_install
	else #UBOOT
		echo "Copying u-boot to SD-CARD"
		sudo cp "$SOURCE"/u-boot/u-boot.bin "$MNT"/fat/
		#update the config.txt
		sudo sed -i.bak '/kernel=/d' "$MNT"/fat/config.txt
		sudo sh -c "echo 'kernel=u-boot.bin' >> '$MNT'/fat/config.txt"
	fi

	#echo "Copying rpi-firmware to SD-CARD"
	#sudo cp -iv "$SOURCE"/rpi-firmware/boot/{bootcode.bin,fixup.dat,start.elf} $MNT/fat

	sync
	sudo umount "$MNT"/fat
	sudo umount "$MNT"/ext4
	echo SDCARD is ready, you can unplug it and try it on your Raspberry pi$RPI board!!!
fi
