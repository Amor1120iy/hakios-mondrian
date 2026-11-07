#!/bin/bash
# Copy the phone's `uefi` partition off a rooted K60. That image is where the vendor's DXE drivers live, and it
# is what UEFIReader (https://uefireader.gzlmortal.eu.org/) takes to give back the driver set the UEFI build
# wants in Binaries/mondrian/.
#
#   devices/mondrian/tools/pull-uefi.sh            # -> work/boot/uefi_a.img
#   then: open the site, pick that file, download the ZIP, unzip its single top directory into
#         Mu-Silicium/Binaries/mondrian/   (QcomPkg/, MdeModulePkg/, RawFiles/, the three .inc files ...)
#
# On this phone: uefi_a = /dev/block/sde1, 5,242,880 bytes, an ELF64 whose payload segment holds the FV. Its
# internal build name is BOOT.MXF.2.0-01018.3-WAIPIO-1 (WAIPIO is the SM8450 family string, so the BSP is a
# cousin's — the drivers are still this phone's own, which is the point).
set -e
cd "$(dirname "$0")/../../.."
adb get-state >/dev/null
mkdir -p work/boot
adb shell su -c "dd if=/dev/block/by-name/uefi_a of=/data/local/tmp/uefi_a.img bs=1M && chmod 644 /data/local/tmp/uefi_a.img"
adb pull /data/local/tmp/uefi_a.img work/boot/uefi_a.img >/dev/null
ls -l work/boot/uefi_a.img
echo "pull-uefi.sh: now upload work/boot/uefi_a.img to https://uefireader.gzlmortal.eu.org/ and unzip the"
echo "pull-uefi.sh: archive's BOOT.MXF.* directory into Mu-Silicium/Binaries/mondrian/"
