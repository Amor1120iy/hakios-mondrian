#!/bin/bash
# Merge this phone's board tree (dtbo.img) onto the SoC tree that vendor_boot.img carries.
#
# prebuilt/device-tree.dtb is the tree out of the phone's vendor_boot.img: the SoC's own
# ("Qualcomm Technologies, Inc. Cape LTE Only SoC"), without the board: no panel, no touch, no haptics.
# The board is the K60's overlay, prebuilt/mondrian-board-overlay.dtb, split out of dtbo.img
# (entry 019: model "Mondrian based on Qualcomm Technologies, Inc SM8475").
#
# HakiOS itself boots with prebuilt/device-tree.dtb alone; the merged tree is what the drivers will
# need once touch, panel and haptics are worked on. It needs dtc 1.6 or later (fdtoverlay), which is
# not part of this tree:
#
#   devices/mondrian/tools/merge-dtbo.sh out/mondrian-merged.dtb
set -e
cd "$(dirname "$(readlink -f "$0")")/.."
OUT=${1:-out/device-tree-merged.dtb}
mkdir -p "$(dirname "$OUT")"
fdtoverlay -i prebuilt/device-tree.dtb -o "$OUT" prebuilt/mondrian-board-overlay.dtb
echo "devices/mondrian/tools/merge-dtbo.sh: $OUT ($(stat -c %s "$OUT") bytes)"
