## Firmware Infos

- **Device:** Redmi K60 (mondrian)
- **Region:** China
- **Version:** `OS3.0.8.0.VMNCNXM` (the vendor_boot/dtbo this port was read from)

The drivers themselves are **not here**: they are Qualcomm's and Xiaomi's, and are extracted from your own phone's
`xbl` with UEFIReader (`uefi/README.md` of the common repository). `Include/APRIORI.inc`, `DXE.inc` and `RAW.inc`
list the files the build asks for; a file listed there that is missing from this directory stops the build, which is
the intended behaviour: it tells you what your extraction still owes.

The list is marble's (the Poco F5, the same Xiaomi cape-family BSP). When your extraction disagrees, replace the
list with what your phone has — that is the port's own business, not marble's.

## Patches/Fixes

The patches below are the ones the reference phone's (redwood's) drivers carry; apply the ones that apply to the
K60's own copies, and record here what you actually did:

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
- **Patch Creator:** [N1kroks](https://github.com/N1kroks)
