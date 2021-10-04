#!/bin/bash

#
# Installs dependencies for the VFDeps package.
#

set -e # Stop as soon as a command fails.
set -x # Print what is being executed.

VFDEPS_NOZ3=vfdeps-2dcfead-win-noz3.txz
curl -o $VFDEPS_NOZ3 -Lf https://vfdeps-cxx-win-noz3.herokuapp.com/$VFDEPS_NOZ3
tar -C /c/ -xjf $VFDEPS_NOZ3

curl -o cygwin-setup-x86.exe -Lf https://cygwin.com/setup-x86.exe
./cygwin-setup-x86.exe -B -qnNd -R c:/cygwin -l c:/cygwin/var/cache/setup -s http://ftp.inf.tu-dresden.de/software/windows/cygwin32/ -P coreutils -P p7zip -P cygutils-extra -P make -P mingw64-i686-gcc-g++ -P mingw64-i686-gcc-core -P mingw64-i686-gcc -P patch -P rlwrap -P libreadline6 -P diffutils -P mingw64-i686-binutils -P m4 -P curl -P python

echo "none /cygdrive cygdrive binary,posix=0,user,noacl 0 0" > c:/cygwin/etc/fstab
