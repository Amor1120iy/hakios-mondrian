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

The two pieces that only come out of a build **are** here now, built on 2026-11-08 (`uefi/README.md` has the
recipe, including how to do it on Windows without Visual Studio):

- `BootShim.bin` — Mu-Silicium's `BootShim` built for this phone's FD (`FD_BASE=0xA7100000`,
  `FD_SIZE=0x300000`, `-DPAYLOAD_BASE=0xf0000000`): 176 bytes,
  sha256 `ddfccdd8589985b9683696b8cb08868007a9e8ee577b867332dbc612155e242a`;
- `SILICIUM_UEFI.fd` — `Build/mondrianPkg/RELEASE_CLANGPDB/FV/SILICIUM_UEFI.fd`, 3,145,728 bytes (the
  0x300000 that `mondrian.toml` promises), sha256
  `b19f15227ef96eaf216a9341f70524b36b00402340d79b972a9595d112053efb`. Its file volume is 99% full: room for
  a driver or two, not for a pile of them.

`py mkxnuimg.py -d mondrian` therefore works and writes `xnu-mondrian.img` (1,490,944 bytes): the shim, the
firmware, and the phone's tree in the kernel slot. It has no XNU in it yet — the payload at `0xf0000000` is
what `make phone` adds when the kernel can be built, which needs the Apple toolchain.

To rebuild them somewhere else:

```sh
devices/mondrian/uefi/apply.sh
cd Mu-Silicium && python3 build_uefi.py -d mondrian -r RELEASE
cd - && make prebuilt            # tools/update-prebuilt.sh, device-aware
```
