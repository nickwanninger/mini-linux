#!/bin/bash

set -e

WORKSPACE=$(pwd)

BUSYBOX_VERSION=1.32.0
CC=${CC:=clang}

echo "Compiling with $CC"


if [ ! -d "linux" ]
then
	git clone git@github.com:torvalds/linux.git --depth 1 linux

	pushd linux >/dev/null
		make CC=$CC defconfig
	popd
fi

# git doesn't like empty files...
mkdir -p root/{bin,sbin,etc,proc,sys,usr/{bin,sbin}}




pushd root
	pwd
	find . -print0 \
		| cpio --quiet --null -ov --format=newc \
		| gzip --quiet -9 > $WORKSPACE/initramfs.cpio.gz
popd


make CC=$CC -C linux -j$(nproc)

qemu-system-x86_64 -m 8G                                 \
	-kernel $WORKSPACE/linux/arch/x86_64/boot/bzImage      \
	-initrd $WORKSPACE/initramfs.cpio.gz \
	-nographic -append "console=ttyS0 init=/init"
