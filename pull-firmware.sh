#!/bin/bash
# Pull the phone's own firmware out of its Android into the fw-*/ directories at the top of the repository
# (never committed: it is the vendor's). The phone is on adb, in Android.
#
# The names are the Redmi K60's (mondrian, SM8475): Adreno 730 for the GPU, WCN6856 for Wi-Fi (where the reference
# phone has a WCN6750 and a660_*), AW882XX amplifiers so there is no haptic firmware to pull (the K60's vibration is
# PM8350B's own block, no file), and the camera's sensor modules are not ported.
set -e
cd "$(dirname "$0")/../.."
pull() { # DIR SOURCE...  (missing files are told, not fatal)
	local dir=$1; shift
	mkdir -p "$dir"
	for f in "$@"; do adb pull "$f" "$dir/" >/dev/null 2>&1 || echo "pull-firmware.sh: $f: not on the phone"; done
	echo "pull-firmware.sh: $dir: $(ls -1 "$dir" | wc -l | tr -d ' ') files"
}
adb get-state >/dev/null
# Adreno 730: the GMU's microcode, the shader's, and the zap shader that TrustZone runs to open the GPU
pull fw-gpu /vendor/firmware/a730_gmu.bin /vendor/firmware/a730_sqe.fw /vendor/firmware/a730_zap.mdt \
	/vendor/firmware/a730_zap.b00 /vendor/firmware/a730_zap.b01 /vendor/firmware/a730_zap.b02
# WCN6856: the WPSS image the Wi-Fi core boots from (ath11k)
pull fw-wifi $(for i in mdt b02 b03 b04 b05 b06 b07; do echo /vendor/firmware_mnt/image/wpss.$i; done)
# the audio DSP: the same split image the reference phone's DSP boots from
pull fw-audio /vendor/firmware_mnt/image/adsp.mdt $(for i in $(seq -w 2 36); do echo /vendor/firmware_mnt/image/adsp.b$i; done)
pull fw-modem /vendor/firmware_mnt/image/modem.mdt $(for i in $(seq -w 0 28); do echo /vendor/firmware_mnt/image/modem.b$i; done)
mkdir -p fw-modem/image && adb pull /vendor/firmware_mnt/image fw-modem/ >/dev/null 2>&1 && \
	echo "pull-firmware.sh: fw-modem/image: the modem's own files (TFTP)"
echo "pull-firmware.sh: done; Wi-Fi also wants fw-wifi/mac (the radio's address) and fw-wifi/network (the network's name and passphrase)"
