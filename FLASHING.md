# Getting it onto the phone, and getting Android back

What was true of the attached Redmi K60 (mondrian, 23013RK75C) on 2026-11-08, read off the phone itself, and the three ways
to run what this repository builds. Read the whole page before the first `fastboot` line.

## What the phone says about itself

| Question | Answer, as measured | How it was read |
|---|---|---|
| Which slot is Android on | `a` | `fastboot getvar current-slot` |
| Is the boot loader unlocked | **yes** — `unlocked: yes`, `Device unlocked: true`, `Device critical unlocked: true` | `fastboot getvar unlocked`, `fastboot oem device-info` |
| What Android's own props say | `ro.boot.flash.locked=1`, `ro.secureboot.lockstate=locked`, `ro.boot.verifiedbootstate=green` | `adb shell getprop` |
| Boot partitions | `boot_a` = sde14, `boot_b` = sde43, `dtbo_a` = sde18, `dtbo_b` = sde47, `vbmeta_a` = sde17, `vbmeta_b` = sde46 | `ls -l /dev/block/by-name` |

**The props lie, the boot loader does not.** `flash.locked=1` and `verifiedbootstate=green` are what a KernelSU install with a
spoofing module wants Play Integrity to see; the boot loader itself reports unlocked and critically unlocked. Trust
`fastboot getvar unlocked` — and nothing else — when deciding whether `fastboot flash` will be refused.

| Partition | Size | SHA-256 | What it is |
|---|---|---|---|
| `boot_a` | 201,326,592 B | `afde8a7fa50fe281868d4b2e33fd643582dcfe3e7147f50a1aeb39f6c7a5a278` | not the stock image: this is the slot Android runs from, with the root patch |
| `boot_b` | 201,326,592 B | `d87847bce22d14475689881e07b3c059f9fedb0ede2ca8156816f57571c01376` | **identical to `images/boot.img` in `mondrian_images_OS3.0.8.0.VMNCNXM_15.0`** — a clean, stock, unused slot |
| `dtbo_a` | 25,165,824 B | `1304a2384d6788c2a9966db2f083910c5772c2ccb0d52eda9c1735220bd2e62e` | stock, and equal to `dtbo_b` |
| `dtbo_b` | 25,165,824 B | `1304a2384d6788c2a9966db2f083910c5772c2ccb0d52eda9c1735220bd2e62e` | stock |

`boot_b` being the stock image is the whole reason an install here can be undone without a cable and without a reflash: the
unpatched system is already sitting in the other slot.

## Keep a copy of both slots first

```sh
mkdir -p backup && cd backup
adb shell su -c 'mkdir -p /data/local/tmp/bk'
for p in boot_a boot_b dtbo_a dtbo_b; do
  adb shell su -c "dd if=/dev/block/by-name/$p of=/data/local/tmp/bk/$p.img bs=1M"
  adb pull /data/local/tmp/bk/$p.img .
done
sha256sum *.img
```

The four hashes above are what this phone gave. `vbmeta_a` cannot be read this way even as root (`Permission denied` from the
`ksu` domain); take the pristine one from the stock package instead — `images/vbmeta.img`, `images/dtbo.img`,
`images/vendor_boot.img` are all there.

## Path 0 — run it from RAM, write nothing (try this first)

```sh
adb reboot bootloader
fastboot boot xnu-mondrian.img          # 1,490,944 B, sha256 7e7630f2…01d
```

Verified on this phone: `Sending 'boot.img' (1456 KB) OKAY`, `Booting OKAY`, and the phone leaves fastboot and runs the image.
Nothing is written to any partition, and the recovery is the power button.

**What to expect today: UEFI, not Darwin.** The image this repository builds right now carries Project Silicium's firmware and
HakiOS's boot shim, and nothing else — `mkxnuimg.py` packs a payload only when `prebuilt/hakios-kernel` exists, and that kernel
needs a Linux (theos + `iPhoneOS16.5.sdk`) or macOS (Xcode) host to build. So the loader comes up, finds no payload, and waits;
`adb` is gone for as long as the phone is in it. Leave it with **a ten-second press of the power key**; it comes back to Android
with everything as it was.

When `make kernel` has produced `hakios-kernel` on a host that can build it, `make prebuilt && make phone` puts it into the
same image, and this exact `fastboot boot` line becomes a real HakiOS session — still writing nothing.

## Path 1 — install beside Android, in the slot Android is not using

Only worth doing once the payload is in the image. The inactive slot is `b`, and it holds the stock image, so the way back is
a slot switch.

```sh
# from the bootloader, with the phone showing the fastboot screen
fastboot --slot b flash boot xnu-mondrian.img
fastboot --slot b --disable-verity --disable-verification flash vbmeta images/vbmeta.img
fastboot --set-active=b
fastboot reboot
```

`--slot b` makes every `flash` land in `boot_b` / `vbmeta_b`; `boot_a`, where Android and the root patch live, is not touched
by any of it. `--disable-verity --disable-verification` are what a modified boot image needs to pass the slot's verification —
with the boot loader unlocked, the flags are accepted; without them the slot may refuse to start.

Back to Android, from the bootloader or from a working Android:

```sh
fastboot --set-active=a
fastboot reboot
```

`boot_a` was never written, so this is a slot flag and nothing else — the fastest way back this phone has.

If slot `b` will not start at all, the same two commands get you back; if the phone will not reach the bootloader, a long power
press plus the key combination for fastboot (power + volume down on this phone) is the way in. **Do not** `fastboot flash` a
`boot` line without `--slot`: without it the command lands in the active slot, which is `a`, which is the slot Android is running
from, and the KSU patch in it is not something this repository can put back.

## Path 2 — the whole system on the phone (not supported yet)

The upstream project's own position, in `docs/install.md` and `docs/install-safe.md` of the kernel repository: writing the boot
chain into a slot and switching to it is **stage 5, not done, not tried**; what Project Silicium's boot manager does when it is
started from a boot slot, and what `vbmeta` says to a modified boot image, are both unknown. Carving `darwin` out of Android's
userdata (`tools/userdata-carve.py`) is a plan that writes nothing. An installer that chains those steps does not exist. Treat
`--slot b flash boot` as the last step of a working port, not the first.

## The short version

1. Back up `boot_a`, `boot_b`, `dtbo_a`, `dtbo_b` and keep the stock package.
2. `fastboot boot` first, every time; it is the only step here that cannot hurt the phone.
3. Install only into slot `b`, and only after the image carries a kernel.
4. `fastboot --set-active=a` is the way back, and it works because slot `a` was never written.
