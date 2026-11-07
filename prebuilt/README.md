# prebuilt/ for mondrian

What is here now:

- `device-tree.dtb` — the phone's own tree, out of `vendor_boot.img` (6,443,651 bytes: the 6,443,651-byte blob at
  0x1f00000 of the v4 vendor_boot header). It is the SoC's tree ("Qualcomm Technologies, Inc. Cape LTE Only SoC",
  `qcom,msm-id = <0x21c 0x10000>`), not the board's: the board (panel, touch, haptics) is an overlay in `dtbo.img`;
- `mondrian-board-overlay.dtb` — that overlay (dtbo entry 019, `Mondrian based on Qualcomm Technologies, Inc SM8475`),
  for `tools/merge-dtbo.sh`;
- `mkbootimg.py`, `ramdisk` — the same two the reference phone ships (the ramdisk is the 5-byte placeholder that
  `mkxnuimg.py` needs for a header-v4 image).

What is **not** here yet, because it only comes out of a build:

- `BootShim.bin` — Mu-Silicium's `BootShim` built for this phone's FD (`FD_BASE=0xA7100000 FD_SIZE=0x300000`,
  `-DPAYLOAD_BASE=0xf0000000`), 176 bytes on the reference phone;
- `SILICIUM_UEFI.fd` — `Build/mondrianPkg/RELEASE_CLANGPDB/FV/SILICIUM_UEFI.fd` (0x300000 bytes: `mkxnuimg.py`
  asserts the size its `.toml` promises).

Both appear here with:

```sh
devices/mondrian/uefi/apply.sh
cd Mu-Silicium && python3 build_uefi.py -d mondrian -r RELEASE
cd - && make prebuilt            # tools/update-prebuilt.sh, now device-aware
```

Until then `make phone` fails in `mkxnuimg.py` with the size it wanted and did not get — that is the intended
failure: it says what is missing.
