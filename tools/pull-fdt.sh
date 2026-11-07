#!/bin/bash
# Copy the device tree off a booted, rooted K60 into prebuilt/device-tree.dtb.
#
# /sys/firmware/fdt is the blob the bootloader handed the kernel: vendor_boot.img's SoC tree with dtbo.img's
# Mondrian overlay already merged into it. That is the tree HakiOS wants -- the SoC-only blob inside
# vendor_boot.img has no panel, no touchscreen and no PM8350B haptics node in it.
#
# The blob is root-only (0400 root), so this needs `adb shell su`, and the phone has to have granted Shell root.
set -e
cd "$(dirname "$0")/../../.."
adb get-state >/dev/null
adb shell su -c "cp /sys/firmware/fdt /data/local/tmp/hakios-fdt.dtb && chmod 644 /data/local/tmp/hakios-fdt.dtb"
adb pull /data/local/tmp/hakios-fdt.dtb devices/mondrian/prebuilt/device-tree.dtb >/dev/null
cp devices/mondrian/prebuilt/device-tree.dtb devices/mondrian/uefi/files/Resources/DTBs/mondrian.dtb
cp devices/mondrian/prebuilt/device-tree.dtb \
	devices/mondrian/uefi/files/Platforms/Xiaomi/mondrianPkg/FdtBlob/sm8475-xiaomi-mondrian.dtb
ls -l devices/mondrian/prebuilt/device-tree.dtb
python3 tools/dtb-check.py devices/mondrian/prebuilt/device-tree.dtb 2>/dev/null || true
