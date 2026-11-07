# prebuilt/ for mondrian

What is here now:

- `device-tree.dtb` — **the phone's own tree, as the phone runs it**: 919,202 bytes, copied off a booted K60 with
  `su -c "cp /sys/firmware/fdt /data/local/tmp/k60-fdt.dtb"` (that is the kernel's `dtb` blob *after* the
  bootloader merged `dtbo.img`'s overlay in, so it is the board's tree and the SoC's in one: model
  `Mondrian based on Qualcomm Technologies, Inc SM8475`, `qcom,msm-id = <0x213 0x10000> <0x21c 0x10000> <0x212 0x10000>`,
  and it carries `qcom,mdss_dsi_m11a_42_02_0a_dsc_cmd`, `xiaomi,m11a-spi` and PM8350B's `qcom,hv-haptics@f000`).
  `tools/pull-fdt.sh` fetches it again from any rooted phone;
- `mondrian-board-overlay.dtb` — dtbo entry 019 of `dtbo.img` on its own, `Mondrian based on Qualcomm Technologies,
  Inc SM8475` (509,094 bytes). Kept for reference and for `tools/merge-dtbo.sh`, which reproduces the merge from
  the two vendor images without a phone;
- `mkbootimg.py`, `ramdisk` — the same two the reference phone ships (the ramdisk is the 5-byte placeholder that
  `mkxnuimg.py` needs for a header-v4 image).

The earlier tree that came out of `vendor_boot.img` (6,443,651 bytes at 0x1f00000 of its v4 header, model
`Qualcomm Technologies, Inc. Cape LTE Only SoC`) was the SoC half only; the merged one above replaces it, because it
is what the bootloader actually hands a kernel on this phone.

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
