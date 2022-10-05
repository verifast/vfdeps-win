#!/bin/bash

#
# Installs dependencies for the VFDeps package.
#

set -e # Stop as soon as a command fails.
set -x # Print what is being executed.

curl -o cygwin-setup-x86_64.exe -Lf https://www.cygwin.com/setup-x86_64.exe
./cygwin-setup-x86_64.exe -B -qnNd -R c:/cygwin -l c:/cygwin/var/cache/setup -s https://ftp.inf.tu-dresden.de/software/windows/cygwin32/ -P coreutils -P rsync -P p7zip -P cygutils-extra -P make -P mingw64-x86_64-gcc-g++ -P patch -P rlwrap -P diffutils -P m4 -P curl -P python -P intltool -P autoconf -P automake -P libtool

echo "none /cygdrive cygdrive binary,posix=0,user,noacl 0 0" > c:/cygwin/etc/fstab
