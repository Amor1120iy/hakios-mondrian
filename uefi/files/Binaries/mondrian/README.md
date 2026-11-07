## Firmware Infos

- **Device:** Redmi K60 (mondrian)
- **Region:** China
- **Version:** `OS3.0.8.0.VMNCNXM`
- **Where the drivers come from:** the phone's own `uefi` partition (`/dev/block/by-name/uefi_a`,
  5,242,880 bytes, an ELF64 whose payload holds the firmware volume). Its internal build name is
  `BOOT.MXF.2.0-01018.3-WAIPIO-1` — WAIPIO is the SM8450 family string, so this BSP is a cousin's, but the
  drivers are this phone's own and that is what matters.

The drivers themselves are **not here**: they are Qualcomm's and Xiaomi's and never published. They come out of
your own phone:

```sh
devices/mondrian/tools/pull-uefi.sh        # dd the uefi partition, adb pull it to work/boot/uefi_a.img
# then, in a browser: https://uefireader.gzlmortal.eu.org/  ->  pick that .img  ->  "下载结果 ZIP"
# unzip the archive's single top directory (BOOT.MXF.2.0-01018.3-WAIPIO-1/) into this directory, so that
# Binaries/mondrian/QcomPkg, Binaries/mondrian/MdeModulePkg, Binaries/mondrian/RawFiles, ... appear here
```

That extraction, done on this phone on 2026-11-08, gives 319 files: 93 `.efi`, 94 `.inf`, 71 `.depex`,
57 `.raw`, one `.te`, and the three list files the vendor BSP built the image from (`DXE.inc`,
`APRIORI.inc`, `DXE.dsc.inc`). **67 drivers under `QcomPkg/Drivers/`**, among them the ones that matter for a
first boot: `UFSDxe`, `DisplayDxe`, `ButtonsDxe`, `SPMIDxe`, `PmicDxe`, `TsensDxe`, `TLMMDxe`, `ClockDxe`,
`RpmhDxe`, `IPCCDxe`, `DALSYSDxe`, `ChipInfoDxe`, `PlatformInfoDxe`, `QcomBds`, and the whole XHCI/USB stack.
`RawFiles/` holds 56 files, including this phone's own panel — `Panel_M11a_42_02_0a_amoled_dsc_cmd.xml.raw` —
`uefiplat.cfg.raw`, `BDS_Menu.cfg.raw` and `PanelSimConfig.csv.raw`.

`Include/APRIORI.inc`, `DXE.inc` and `RAW.inc` are generated from those three vendor lists by
`uefi/make-includes.py`: the `QcomPkg` part is exactly what this phone has, in the order its BSP built it, and
only files that the extraction actually produced are listed, so a listed file that is missing from this
directory still stops the build — that is the intended behaviour: it tells you what your extraction still owes.
The non-`QcomPkg` lines (MdeModulePkg, ArmPkg, EmbeddedPkg, FatPkg, SiliciumPkg) stay as they were, because the
edk2 modules are built from source and their module names are not the ones the vendor's internal tree used.

## Patches/Fixes

The patches below are the ones the reference phone's (redwood's) drivers carry. The extracted copies here are
this phone's *unpatched* drivers, so apply the ones that apply and record below what you actually did:

### ButtonsDxe:

- **Reason:** To make the Power Button usable in UEFI.
- **Patch:** The Special Qcom Key Code (`0x102`) has been Changed to the Key Code Enter (`0xD`).
- **Patch Creator:** [Gustave Monce](https://github.com/gus33000)

### DALSYSDxe:

- **Reason:** To avoid Mismatched Cached Copies.
- **Patch:** Enabled Cache Coherence for UFS.
- **Patch Creator:** [Gustave Monce](https://github.com/gus33000)

### TzDxeLA:

- **Reason:** To make UEFI not Crash during UEFI Boot.
- **Patch:** The Global TZ Applet Variable has been Changed to `TRUE` from `FALSE`.
- **Patch Creator:** [N1kroks](https://github.com/N1kroks/)

### UsbConfigDxe:

- **Reason:** To make USB work in the OS.
- **Patch:** The USB Deinit Code has been Removed from Exit Boot Services Event to allow the OS to continue using the USB Port.
- **Patch Creator:** [Gustave Monce](https://github.com/gus33000)

### UsbMsdDxe:

- **Reason:** To make the Internal Storage be recognised as Hard Drives instead of USB Drives in Mass Storage.
- **Patch:** Changed Removable State to Non-Removable.
- **Patch Creator:** [N1kroks](https://github.com/N1kroks/)
