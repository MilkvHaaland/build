#!/bin/bash -e

export PATH="/opt/Xuantie-900-gcc-linux-5.10.4-glibc-x86_64-V2.6.1/bin:$PATH"
export CROSS_COMPILE=riscv64-unknown-linux-gnu-
export ARCH=riscv

usage() {
    echo "====USAGE: mk-kernel.sh -b <board_name> -r <release_number>===="
    echo "mk-kernel.sh -b milkv-meles -r 1"
}

while getopts "b:r:h" flag; do
    case $flag in
    b)
        export BOARD="$OPTARG"
	    ;;
    r)
        export RELEASE_NUMBER="$OPTARG"
        ;;
    esac
done

if [ ! $BOARD ] || [ ! $RELEASE_NUMBER ]; then
    usage
    exit
fi

LOCALPATH=$(pwd)
OUT=${LOCALPATH}/out
BUILD=${LOCALPATH}/build
THEAD_BIN=${LOCALPATH}/thead-bin

[ ! -d ${OUT}/boot ] && mkdir -p ${OUT}/boot
[ ! -d ${OUT}/rootfs ] && mkdir -p ${OUT}/rootfs
rm -rf ${OUT}/rootfs/lib/modules/*

generate_boot_image() {
	BOOT=${OUT}/boot.ext4
	TMP=${OUT}/tmp
	sudo rm -rf ${BOOT} ${TMP}
	mkdir ${TMP}

	echo -e "\e[36m Generate Boot image start\e[0m"

	# 100MB
	dd if=/dev/zero of=${BOOT} bs=1M count=100
	mkfs.ext4 ${BOOT}

	sudo mount ${BOOT} ${TMP}
	sudo mkdir ${TMP}/extlinux
	sudo cp ${BUILD}/extlinux/extlinux.conf ${TMP}/extlinux
	sudo cp -av ${OUT}/boot/* ${TMP}
	sudo umount ${TMP}
	echo -e "\e[36m Generate Boot image : ${BOOT} success! \e[0m"
}

build_kernel() {
	cd thead-kernel
	export kernelversion=$(make kernelversion)
	export number=${RELEASE_NUMBER}
	export gid="g$(git rev-parse --short HEAD)"
	export kv="-$number-$gid"

	make CROSS_COMPILE=riscv64-unknown-linux-gnu- ARCH=riscv revyos_defconfig LOCALVERSION=${kv}
	make CROSS_COMPILE=riscv64-unknown-linux-gnu- ARCH=riscv -j$(nproc) LOCALVERSION=${kv}
	make CROSS_COMPILE=riscv64-unknown-linux-gnu- ARCH=riscv -j$(nproc) dtbs LOCALVERSION=${kv}
	make CROSS_COMPILE=riscv64-unknown-linux-gnu- ARCH=riscv INSTALL_MOD_PATH=${OUT}/rootfs modules_install -j$(nproc) LOCALVERSION=${kv}

	mkdir -p ${OUT}/boot/dtb/thead
	cp -v arch/riscv/boot/Image ${OUT}/boot/
	cp -v arch/riscv/boot/dts/thead/*.dtb ${OUT}/boot/

	cp -v ${THEAD_BIN}/opensbi/${BOARD}/* ${OUT}/boot/

	rm -rf ${OUT}/rootfs/lib/modules/${kernelversion}${kv}/build
	rm -rf ${OUT}/rootfs/lib/modules/${kernelversion}${kv}/source
}

build_kernel
generate_boot_image

echo -e "\e[36m Kernel build success! \e[0m"
