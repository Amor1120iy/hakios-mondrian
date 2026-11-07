#!/bin/bash
# Pull the phone's own firmware out of its Android into the fw-*/ directories at the top of the repository
# (never committed: it is the vendor's). The phone is on adb, in Android, rooted (the firmware is root-only).
#
# The names below are what the Redmi K60 (mondrian, SM8475) actually has on its own partitions, read off a running
# phone on 2026-11-08 (root, `ls /vendor/firmware_mnt/image` and `ls /vendor/firmware`):
#
#   GPU    Adreno 730: a730_sqe.fw, a730_zap.{mdt,b00..b02}, and the GMU's image is gmu_gen70000.bin --
#          there is no a730_gmu.bin (that is the a6xx naming the reference phone uses for its Adreno 642L)
#   Wi-Fi  WCN6856: the whole qca6490/ directory (222 files: amss.bin, amss20.bin, m3.bin, regdb.bin,
#          regdb_xiaomi.bin, bdwlan.e01..e1d, bd_*.elf board data, Data.msc/Data20.msc).
#          There is no wpss.mdt here: that is WCN6750's scheme, not this radio's.
#   audio  adsp.mdt + adsp.b00..b25 in /vendor/firmware_mnt/image
#   modem  modem.mdt + modem.b00.. (30 entries) in /vendor/firmware_mnt/image
#   IPA    ipa_fws.mdt + ipa_fws.b00..b04 (the boot argument says soc_ipa_fw=ipa_fws)
#   others cdsp.* (18), slpi.* (24) -- not pulled: nothing in the port needs them yet
#   haptic nothing: the K60's vibration is PM8350B's own hv-haptics block, it has no firmware file
#   camera nothing yet: the sensor modules are not ported, and maui/kona's com.qti.sensormodule.* files are
#          not on this phone's firmware partitions at all (Xiaomi keeps them in /vendor/lib/camera)
set -e
cd "$(dirname "$0")/../.."
FW=/vendor/firmware
FWI=/vendor/firmware_mnt/image
adb get-state >/dev/null
pull() { # DIR SOURCE...  (missing files are told, not fatal; root copies them out of the read-only mount)
	local dir=$1; shift
	mkdir -p "$dir"
	for f in "$@"; do adb shell su -c "cp $f /data/local/tmp/hakios-fw" >/dev/null 2>&1 &&
		adb pull /data/local/tmp/hakios-fw "$dir/$(basename "$f")" >/dev/null 2>&1 ||
		echo "pull-firmware.sh: $f: not on the phone"
	done
	echo "pull-firmware.sh: $dir: $(ls -1 "$dir" | wc -l | tr -d ' ') files"
}
# Adreno 730: the shader's, the zap shader TrustZone runs to open the GPU, and the GMU's microcode
pull fw-gpu $FW/a730_sqe.fw $FW/a730_zap.mdt $FW/a730_zap.b00 $FW/a730_zap.b01 $FW/a730_zap.b02 \
	$FW/gmu_gen70000.bin
# WCN6856: the radio boots a whole directory, not a split image -- copy it over as one
adb shell su -c "cp -r $FWI/qca6490 /data/local/tmp/hakios-qca6490" >/dev/null 2>&1 || true
mkdir -p fw-wifi
adb pull /data/local/tmp/hakios-qca6490 fw-wifi/ >/dev/null 2>&1 &&
	echo "pull-firmware.sh: fw-wifi/qca6490: $(ls -1 fw-wifi/qca6490 | wc -l | tr -d ' ') files" ||
	echo "pull-firmware.sh: $FWI/qca6490: not on the phone"
# the audio DSP: the same split image the reference phone's DSP boots from
pull fw-audio $FWI/adsp.mdt $(for i in $(seq -w 0 25); do echo $FWI/adsp.b$i; done)
pull fw-modem $FWI/modem.mdt $(for i in $(seq -w 0 29); do echo $FWI/modem.b$i; done)
pull fw-ipa $FWI/ipa_fws.mdt $(for i in $(seq -w 0 4); do echo $FWI/ipa_fws.b$i; done)
echo "pull-firmware.sh: done"
echo "pull-firmware.sh: Wi-Fi also wants fw-wifi/mac (the radio's address) and fw-wifi/network"
