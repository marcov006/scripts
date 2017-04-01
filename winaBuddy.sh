#!/bin/bash
#Helper to install/run winamax under wine

set +eux

PREFIX=$HOME/.wine32-wina
HELP=false
INSTALL=false
RUN=false

MACHINE_TYPE=`getconf LONG_BIT`
if [ ! ${MACHINE_TYPE} == '32' ]; then
	echo Winamax under wine needs 32-bits... schroot?
	exit 1
fi

while true; do
	case "${1:-unset}" in
		-h | --help) HELP=true; shift ;;
		-i | --install) INSTALL=true; shift;;
		-p | --prefix) PREFIX=$(readlink -f "$2"); shift 2;;
		--) shift; break;;
		*) RUN=true; break;;
	esac
done

function install {
	winecfg #xp mode
	file=WinamaxInstall.exe
	if [ -f $DL_DIR/$file ]; then
		echo "$file found in $DL_DIR!"
	else
		wget https://dl.vip.winamax.fr/client/wam/$file
		cp $file $DL_DIR
	fi
	WINEARCH=win32 env WINEPREFIX="$PREFIX" wine $DL_DIR/$file
}

if $INSTALL;
then
	install
fi

function help {
	cat <<EOF
NAME:
	$0 - Helper to install/run winamax under wine

OPTIONS:
	--help: This output messge
	--prefix: Where to install the .wine
	--install: Install winamax under wine
	--run: Play poker!
EOF
	exit 0
}

if $HELP;
then
	help
fi

if $RUN;
then
	wine "$PREFIX/drive_c/users/$(whoami)/Winamax/Winamax Poker/Winamax Poker.exe"
fi
