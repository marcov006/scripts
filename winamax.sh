#!/bin/bash

#dpkg --add-architecture i386 && apt-get update
#apt-get install wine-development
#winecfg-development #xp mode

#file=WinamaxInstall.exe
#wget https://dl.vip.winamax.fr/client/wam/$file

#wine-development "$HOME/.wine/drive_c/users/$(whoami)/Winamax/Winamax Poker/Winamax Poker.exe"
wine "$HOME/.wine/drive_c/users/$(whoami)/Winamax/Winamax Poker/Winamax Poker.exe"

#wine-development "/root/.wine/drive_c/users/root/Winamax/Winamax Poker/Winamax Poker.exe"
