#!/bin/bash -e

usage() {
    echo "====USAGE: mk-uboot.sh -b <board_name>===="
    echo "mk-uboot.sh -b light-milkv-meles"
}

while getopts "b:h" flag; do
    case $flag in
	b)
	    export BOARD="$OPTARG"
	    ;;
    esac
done

if [ ! $BOARD ]; then
    usage
    exit
fi


case ${BOARD} in
	"light-milkv-meles")
		UBOOT_DEFCONFIG=light_milkv_meles_defconfig
		export ARCH=riscv
		export CROSS_COMPILE=riscv64-unknown-linux-gnu-
		;;
	*)
		echo "board '${BOARD}' not supported!"
		exit -1
		;;
esac

LOCALPATH=$(pwd)
OUT=${LOCALPATH}/out

cd thead-u-boot

make ${UBOOT_DEFCONFIG}
make -j BUILD_TYPE=RELEASE

cp u-boot-with-spl.bin ${OUT}

echo -e "\e[36m U-Boot build success! \e[0m"
