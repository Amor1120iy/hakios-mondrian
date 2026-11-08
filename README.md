# mondrian — Redmi K60

HakiOS on the Redmi K60 (Xiaomi `mondrian`, Qualcomm SM8475 "cape"/"cape-v2", Snapdragon 8+ Gen 1),
8 cores (1 X2 + 3 A710 + 4 A510), Adreno 730, 1440×3200, UFS.

This is a **port in progress**: the device layer, the SoC layer, the UEFI platform and the pieces of
the kernel that had the reference phone's addresses baked in are here; the phone's own drivers (its
panel, its touch controller, its PMIC haptics, its GPU, its Wi-Fi) are not. `device.conf` says exactly
which area is where, and the last section of this file says what each driver still needs.

Everything in this directory was read out of the phone's own firmware, `mondrian_images_OS3.0.8.0.VMNCNXM`
(`vendor_boot.img`'s device tree, `dtbo.img`'s overlays, `boot.img`'s header) and then out of the phone itself
once it was rooted (its runtime device tree, its `thermal_zone*` names, its `kgsl` clocks, its `/vendor` firmware
directories) — no number here is the reference phone's. The last section but one, *What the phone says about
itself*, is the measured half.

## Status

`device.conf` is the machine-readable copy of this table.

| area | state | what it means |
| --- | --- | --- |
| display | partial | the UEFI's framebuffer, through the loader; no panel driver, no backlight, no DSI |
| touch | missing | Goodix `m11a` on QUP4; the driver in this tree speaks the POCO X5 Pro's pins |
| buttons | partial | the arbiter is reachable at the K60's addresses; the keys' own pins are the reference phone's |
| cpu | partial | EPSS and RSC are parameterised and set from `soc.args`; not run |
| gpu | missing | Adreno 730; the driver speaks the Adreno 642L's GMU, and `hakios-metal` knows one chip id |
| storage | partial | UFS at the K60's addresses (same as the reference phone's), UFS 3.1 gear unknown |
| audio | missing | AW882xx amplifiers, Qualcomm codec; the driver speaks the reference phone's |
| battery | missing | PM8350B; the driver goes through the ADSP |
| haptic | missing | PM8350B `qcom,hv-haptics`; the driver speaks an AW86927 over I²C |
| camera | missing | the reference phone's sensors, `cape-camcc` |
| torch | missing | PM8350C flash |
| wifi | missing | WCN6856; the driver speaks a WCN6750 |
| bluetooth | missing | three-wire, as on the reference phone |
| cellular | missing | SM8475 modem, IPA v4.11; needs the modem firmware and a Darwin user space |
| network | missing | follows wifi and cellular |
| thermal | works, unverified | tsens at 0xc263000/0xc265000 (same addresses as the reference phone); the K60's own 32-sensor map is in the driver, selected by `thermal_map=sm8475` from its tree |
| usb | missing | not started |
| sensors | missing | not started |

## What is in this directory

```
device.conf                 the area table above
soc.args                    what differs from the reference phone's SoC (tools/hakios-device.py reads it)
configs/mondrian.config     this phone's switches: UFS only, the rest off with the reason written next to it
configs/mondrian_defconfig  common_defconfig + sm8475.config + mondrian.config
soc/soc.conf                the SoC layer's identity (SM8475, 8 cores, Adreno 730)
soc/configs/sm8475.config   CONFIG_SOC, cores, bootcpu, cpufreq/socinfo/thermal on
metal.args                  what hakios-metal gets (fb_hz=60 fb_threads=3; the GPU is not supported yet)
pull-soc.sh                 read the SoC's addresses off the phone (needs adb; soc-args.py does the reading)
pull-firmware.sh            read the GPU/Wi-Fi/audio/modem firmware off the phone's /vendor
prebuilt/device-tree.dtb    the phone's tree as it runs it, /sys/firmware/fdt (919,202 bytes, SoC + board merged)
prebuilt/mondrian-board-overlay.dtb   the board's overlay on its own, out of dtbo.img (entry 019)
prebuilt/{mkbootimg.py,ramdisk}       what mkxnuimg.py packs with
prebuilt/README.md          what is missing there and which command makes it
uefi/apply.sh               put this phone's platform into Mu-Silicium (uefi/apply.sh mondrian)
uefi/export.sh              take it back out
uefi/files/…                the platform: memory map, configuration map, driver list, FDT blob, mondrian.toml
uefi/README.md              what was borrowed from marble (the Poco F5) and why
tools/pull-fdt.sh           copy /sys/firmware/fdt off a rooted phone into prebuilt/ and the two UEFI copies
tools/merge-dtbo.sh         fdtoverlay the board onto the SoC tree, from the two vendor images, without a phone
```

`make mondrian_defconfig`, then `make phone`. Read `prebuilt/README.md` first: `make phone` needs
`BootShim.bin` and `SILICIUM_UEFI.fd`, which only a UEFI build produces.

## Where the numbers come from

The tree this port ships (`prebuilt/device-tree.dtb`, 919,202 bytes) is not either of those blobs: it is
`/sys/firmware/fdt` — what the bootloader actually hands a kernel after merging `dtbo.img` into
`vendor_boot.img`'s tree. The two vendor blobs are kept apart below because that is how they arrive, and
`tools/merge-dtbo.sh` rebuilds the merge from them when there is no phone to ask.

`vendor_boot.img` (page 4096, header v4) carries the SoC's device tree at 0x1f00000: 6,443,651 bytes,
model `Qualcomm Technologies, Inc. Cape LTE Only SoC`, `qcom,msm-id = <0x21c 0x10000>`. It has no
panel, no touch controller and no haptics: those are in `dtbo.img`, whose 44 overlays are the Xiaomi
and Qualcomm board trees; entry 019 is this phone's (`model = "Mondrian based on Qualcomm Technologies,
Inc SM8475"`, `qcom,board-id = 0x10008`, `xiaomi,miboard-id = 0xe`).

`soc.args` was made by `tools/soc-args.py` from that tree, then corrected by hand for the four
addresses that script does not read (it prints 12 of the 16):

| key | value | where in the tree |
| --- | --- | --- |
| `soc_ipa_base` | 0x3e40000 | `qcom,ipa@3e00000`, `reg-names = "ipa-base"` |
| `soc_gsi_base` | 0x3e04000 | same node, `"gsi-base"` |
| `soc_ipcc` | 0xed18000 | `qcom,ipcc@ed18000` |
| `soc_rsc` | 0x17a20000 | `rsc@17a00000`, `drv-2` |
| `soc_mpss_mem` | 0x8bc00000 | `reserved-memory/mpss@8bc00000` (0x13200000 long) |
| `modem_ipa_fw_at` | 0x8b900000 | `ipa_fw@8b900000` + `ipa_gsi@8b910000` |
| `soc_ipa_fw` | `ipa_fws` | `qcom,ipa_fws`, `qcom,firmware-name` |
| `soc_epss` | 0x17d91000 | `qcom,cpufreq-hw-epss`, `freq-domain0` |
| `ddr_mc` / `ddr_sh` | MC3 / SH5 | `qcom,dcvs-fp`, `ddr-bcm-name` / `llcc-bcm-name` |
| `soc_spmi_core` | 0xc400000 | `qcom,spmi@c42d000`, `reg-names = "core"` |
| `soc_spmi_cnfg` | 0xc42d000 | same node, `"cnfg"` |
| `soc_spmi_obs` | 0xc440000 | same node, `"obsrvr"` |

Left out on purpose: `soc_ipa_stream=0x5c0` and `soc_ipa_stream_uc=0x5c2`. The loader's command line
holds 607 characters and a run already spends about 260; those two only matter once `CONFIG_MODEM` is
on, and they are in `soc.args` as a comment for that day.

Given by the configuration: `thermal_map=sm8475` (from `CONFIG_THERMAL_MAP`) — without it the driver uses
the reference phone's sensor layout, and on this SoC that reads the wrong sensor for every name past the
first four (the K60 puts `cpuss-0..3` on block 0 and `cpu-0-0..3` on block 1, and has `cpu-1-8`, `nspss-2`
and `camera-1` that the SC7280 does not). The map itself was made by `tools/dt-thermal.py` from the phone's
own `/sys/firmware/fdt`; both tables live in `drivers/power/hakios.thermal.c`.

Not needed: `thermal_tm0`/`thermal_tm1` (0xc263000/0xc265000 are already the defaults) and
`cpu_domains` (default `0,0,0,0,1,1,1,2` is this phone's 4+3+1 cluster split; the K60's EPSS has the
same three frequency domains in the same order, biggest core last).

## How a run looks

```sh
make mondrian_defconfig
devices/mondrian/uefi/apply.sh
(cd Mu-Silicium && python3 build_uefi.py -d mondrian -r RELEASE)
make prebuilt
make phone SECS=120          # or: ./xl enter / ./xl ramdisk / ./xl run, see docs/porting/index.md
```

The boot line an image gets is what `tools/hakios-config.py args` prints, plus `soc.args`:

```
cpus=8 bootcpu=7 cpufreq=1 ufs=2 socinfo=1 thermal=1
soc_ipa_base=0x3e40000 soc_gsi_base=0x3e04000 soc_ipcc=0xed18000 soc_rsc=0x17a20000
soc_mpss_mem=0x8bc00000 modem_ipa_fw_at=0x8b900000 soc_ipa_fw=ipa_fws
soc_epss=0x17d91000 ddr_mc=MC3 ddr_sh=SH5
soc_spmi_core=0xc400000 soc_spmi_cnfg=0xc42d000 soc_spmi_obs=0xc440000
```

`debug=0x8 rd=md0 hv_wdt_pet=1` are the loader's (see `docs/boot-args.md`); without a ramdisk the
kernel panics at `IOKitBSDInit.cpp:926 Failed to mount root device`, which is expected until a Darwin
user space is built from an IPSW (`userland/build.sh`).

The UEFI writes its FD at 0xa7100000 (0x300000, `uefi/files/Resources/Configs/mondrian.toml`) and the
payload at 0xf0000000 (`BootShim`'s `-DPAYLOAD_BASE`), the same two places the reference phone uses.
`mkxnuimg.py` reads the FD's base, size and the boot image's header version out of that `.toml` — the
K60's own `boot.img` is a v4 image, and the `.toml` says 4.

## What changed in the common tree for this port

The rule: no SoC logic changes, and every address that was the reference phone's becomes a boot
argument whose default is still the reference phone's value — so `redwood` behaves exactly as before.

| file | change |
| --- | --- |
| `drivers/power/hakios.cpufreq.c` | `EPSS_PHYS`/`RSC_PHYS` became `*_DEFAULT`; `epss_phys`, `rsc_phys`, `cpu_domain[8]`, `ddr_mc_name`/`ddr_sh_name` are new; `hakios_cpufreq_init()` reads `soc_epss`, `soc_rsc`, `cpu_domains`, `ddr_mc`, `ddr_sh` |
| `drivers/input/hakios.buttons.c` | the three arbiter addresses are `*_DEFAULT` + `arb_where()` reads `soc_spmi_core`/`soc_spmi_cnfg`/`soc_spmi_obs` |
| `drivers/power/hakios.pmic.c` | the same three, through `arb_where()` |
| `drivers/core/hakios.socinfo.c` | SM8475 added to the SoC-number table (two candidate ids: 530 and 536 — check `/sys/devices/soc0/soc_id` on Android; a wrong id only costs a name) |
| `xnuloader/loader.c` | `platform_sm8475` (GIC at 0x17a00000, GICR at 0x17a60000, 8 cores, 4 small ones); it is chosen when the framebuffer is at least 1440 high; `charger_start()`/`wdt_arm()` now test `phone_platform()` instead of "is redwood" |
| `mkxnuimg.py` | `-d/--device`; FD base/size and the header version come from `devices/<dev>/uefi/files/Resources/Configs/<dev>.toml` |
| `tools/update-prebuilt.sh` | takes the device from `.config` (`CONFIG_DEVICE`) instead of hard-coding redwood |
| `docs/boot-args.md`, `configs/boot-args.lst`, `configs/symbols.tsv` | regenerated: 358 arguments |

## What the phone says about itself

Measured on a booted, rooted K60 (`adb shell su`) on 2026-11-08, firmware `OS3.0.8.0.VMNCNXM`. These are the
numbers the drivers are written against; where they disagree with the reference phone's, the driver is what has
to move.

| what | how it was read | what it says |
| --- | --- | --- |
| SoC number | `cat /sys/devices/soc0/soc_id` | **530** — `hakios.socinfo.c`'s table has 530 for "SM8475 (\"cape\")", so the guess was right (`machine` = `CAPE`, `platform_version` = 65536, `revision` = 1.0) |
| panel | `cat /sys/class/drm/card0-DSI-1/modes` | `1440x3200x60cmd`, `1440x3200x90cmd`, `1440x3200x120cmd` — command mode, three rates; backlight is `/sys/class/backlight/panel0-backlight` |
| GPU | `cat /sys/class/kgsl/kgsl-3d0/gpu_model` | **`Adreno730`**, `max_gpuclk` 900 MHz, 13 steps (900, 862, 815, 765, 710, 645, 580, 515, 439, 364, 324, 285, 220 MHz) |
| touch | `/proc/bus/input/devices` | `goodix_ts` on `event7` (plus `uinput-goodix` on `event1`) — one controller, no second source |
| keys | `/proc/bus/input/devices` | `gpio-keys` `event0`, `pmic_pwrkey` `event2`, `pmic_resin` `event3`, and the two "bark" wakeup devices `event4`/`event5` |
| haptics | `/proc/bus/input/devices` | `qcom-hv-haptics` on `event6` — the PM8350B block, reached as `c42d000.qcom,spmi:qcom,pm8350b@3:qcom,hv-haptics@f000` in dmesg |
| SPMI | `dmesg` | every PMIC device hangs off **`c42d000.qcom,spmi`** — the `cnfg` window of `qcom,spmi@c42d000`; the arbiter's `core` stays 0xc400000 and `obsrvr` 0xc440000 |
| PMICs | `thermal_zone*` names | `pm8350`, `pm8350c`, `pm8350b`, `pmr735a`, `pmr735b` — the five the device tree names |
| thermal | `cat /sys/class/thermal/thermal_zone*/type` | 71 zones. The tsens ones: `aoss-0`, `cpuss-0..3`, `cpu-1-0..cpu-1-8`, `cpu-0-0..3`, `nspss-0..2`, `video`, `ddr`, `mdmss-0..3`, `camera-0`, `camera-1`, `gpuss-0/1`, `aoss-1`. That is **three more sensors than the reference phone's 26** (`cpu-1-8`, `nspss-2`, `camera-1`), so `hakios.thermal.c`'s table is not just renamed, it is short |
| battery, USB | `ls /sys/class/power_supply` | `battery`, `usb`, `wireless`, `ucsi-source-psy-soc:qcom,pmic_glink:qcom,ucsi1` |
| torch, LEDs | `ls /sys/class/leds` | `led:torch_0..3`, `led:flash_0..3`, `led:switch_0..2` — a three-LED PM8350C flash plus the switch |
| UFS | `ls /sys/class/scsi_host` | `host0`, `proc_name` = `ufshcd` |
| firmware | `ls /vendor/firmware_mnt/image`, `ls /vendor/firmware` | `adsp.*` 26 files, `cdsp.*` 18, `slpi.*` 24, `modem.*` 30, `ipa_fws.*` 6, `qca6490/` 222, and in `/vendor/firmware`: `a730_sqe.fw`, `a730_zap.{mdt,b00,b01,b02}`, `gmu_gen70000.bin` |
| device tree | `cat /sys/firmware/fdt` | 919,202 bytes, `model = "Mondrian based on Qualcomm Technologies, Inc SM8475"` — the merged tree this port ships as `prebuilt/device-tree.dtb` |
| boot line | `cat /proc/cmdline` | `msm_drm.dsi_display0=qcom,mdss_dsi_m11a_42_02_0a_dsc_cmd:` (the panel the board tree names), `mtdoops.fingerprint=mondrian:12/OS3.0.8.0.VMNCNXM:user`, `hwid.project=14`, `log_buf_len=2M` |

## What each remaining driver needs

The pattern is always the same: the driver in this tree was written against the POCO X5 Pro (SC7280 /
SM7325, "yupik"), so the register *addresses* are often right (Qualcomm moved very little between
yupik and cape) while the *chip*, the *pins* and the *firmware names* are not. Each line below is a
place to look, not a complete plan.

**touch** — `drivers/input/hakios.goodix.c:27` reads `pinctrl-sc7280`/`gcc-sc7280`/`cmd-db`. The K60's
controller is a Goodix `m11a` on QUP4: SPI 15 MHz on GPIO 16/17/18, chip select 19, interrupt 21
(active high, rising edge), reset 20, AVDD 71, IOVDD from `vdd`; firmware `goodix_firmware_m11a`,
config group `goodix_cfg_group_m11a`. The panel is 1440×3200 (`panel-max-x = 0x3840`,
`panel-max-y = 0x7d00`), and the touch node's `interrupt-parent` is the SPI controller, so the
interrupt must be taken from TLMM 21, not from the controller.

**haptic** — the K60 has no AW86927: it is the PM8350B's `qcom,hv-haptics@f000` (`reg` 0xf000/0xf100/
0xf200, interrupt PM8350B `0xf0`, `vmax-mv = 1250`, `lra-period = 5882` µs, brake mode 1, brake
pattern `0xff3f1f`, `nvmem` `hap_cl_brake`, a PBS client and a soundwire slave). That is an SPMI
peripheral reached through the arbiter this port now points at the right place — `drivers/haptic/`
needs a second backend beside `hakios.haptic.c`'s AW86927 one, and `CONFIG_HAPTIC`'s step number
(1 = identify, 2 = release reset, 3 = load firmware, 4 = play once, 5 = hand it to Darwin) means
something different for a PMIC haptics block: steps 1 and 2 make sense, 3 does not (no firmware file).

**gpu** — `drivers/gpu/hakios.adreno.c` is the Adreno 642L's: `gpucc` is mapped at
`0x03d90000`/`0x9000` (the K60's `cape-gpucc` is 0x3d90000/0xa000 — the same block, a longer
window), the speed bin is read from the efuse at `0x784000` (line 410: the SM8475's efuse is
elsewhere), and lines 444–445 name the parts 0xac/0xbe "643" and everything else "642L" — the K60's
GPU is an Adreno 730, with `a730_sqe.fw`, `a730_zap.mdt/.b00-.b02`, and its GMU image is `gmu_gen70000.bin`
(there is no `a730_gmu.bin` on this phone; `pull-firmware.sh` pulls the four that exist). The measured
`kgsl` facts are in *What the phone says about itself*: `Adreno730`, 900 MHz maximum, 13 steps. `hakios-metal` knows a single chip id (0x06030500) and refuses anything
else, so the display stays on the framebuffer until that table grows.

**wifi** — the K60 has a WCN6856, the driver speaks a WCN6750 (`drivers/wifi/hakios.wifi.c:151`), and the
two radios do not even share a firmware scheme: the WCN6750 boots a split image (`wpss.mdt` + `.b02`–`.b07`),
while this phone carries a whole directory, `/vendor/firmware_mnt/image/qca6490/` (222 files: `amss.bin`,
`amss20.bin`, `m3.bin`, `regdb.bin`, `regdb_xiaomi.bin`, `bdwlan.e01`–`e1d`, 42 `bd_*.elf` board files and
two `.msc` files). `pull-firmware.sh` copies that directory as it is.
Its own copies of the SoC's addresses are still hard-coded and are *not* all the K60's:
`ipcc` at 0x408000 (line 843; the K60's is 0xed18000), `rsc` at 0x18220000 (line 1003; 0x17a20000),
the arbiter at 0xc440000/0xc40a000/0xe600000 (lines 1069–1071; the K60's are
0xc400000/0xc42d000/0xc440000). `aoss` (0xc300000) and `cmd_db` (0x80860000) are already right.
They become boot arguments the same way the cpufreq driver's did, once Wi-Fi is worked on; until then
`CONFIG_WIFI` stays off, so they are inert.

**audio** — the K60's amplifiers are AW882xx at I²C 0x34/0x35 (`aw882xx_smartpa`), not the reference
phone's; the codec path is the same Qualcomm one. `drivers/audio/hakios.sound.c:59` and
`hakios.speaker.c:63` cite `pinctrl-yupik`, and the pins they program (GPIO 97/98/99/100 for MI2S0)
are the reference phone's.

**camera** — `drivers/camera/hakios.camera.c:9` is `camcc-yupik`; the K60's is `qcom,cape-camcc` at
0xade0000 (line 824's `GCC_CAMERA_AHB_CBCR` and the PLL/MCLK numbers at 846 are yupik's), and the
sensors are not the reference phone's at all (the K60's board tree names `csiphy-v2.1.3-xiaomi-m11a`).

**modem** — `drivers/modem/hakios.mpss.c` hard-codes `yupik_ipa_fws` (lines 1789, 2211–2216, 2226)
and the IPA firmware's load address `0x8b710000` (line 1804, with 0x8b700000 as the alternative).
The K60's `qcom,ipa_fws` says `ipa_fws`, and its reservations put `ipa_fw` at 0x8b900000 and
`ipa_gsi` at 0x8b910000 — `soc_ipa_fw` already covers the name, `modem_ipa_fw_at` the address
(0x8b900000 here). `drivers/modem/hakios.ipa.c:57-63` is already parameterised (`soc_ipa_base`,
`soc_gsi_base`) and the K60's IPA is v4.11, the same generation as the reference phone's.

**thermal** — nothing to do for the addresses, everything for the names: `drivers/power/hakios.thermal.c`
lists 26 sensors as "aoss-0, cpu-0-0 …" from the reference phone's tree. The K60's tsens blocks are at
the same addresses with the same register layout (`qcom,tsens-v2`), but which channel is which sensor
is the phone's own business — read its `thermal-zones` once the blocks answer.

## The firmware is built

`uefi/README.md` now ends with the recipe that actually produced it on this Windows box, no Visual Studio:
clang + `mingw32-make` for the "mingw32 host" path, `rc.exe` from `llvm-rc`, BaseTools' python paths fixed,
`PYTHONUTF8=1` for a Chinese locale, and `lisa`'s ACPI tables. The result:

| piece | size | sha256 |
| --- | --- | --- |
| `prebuilt/SILICIUM_UEFI.fd` | 3,145,728 (0x300000) | `b19f15227ef96eaf216a9341f70524b36b00402340d79b972a9595d112053efb` |
| `prebuilt/BootShim.bin` | 176 | `ddfccdd8589985b9683696b8cb08868007a9e8ee577b867332dbc612155e242a` |
| `xnu-mondrian.img` (kernel slot) | 1,490,944 | `7e7630f29d98bbc283caf98c6186dad43c7a4ecaeff33d39e54456c1f017a01d` |

The image has the firmware and the shim but not XNU: the kernel needs the Apple toolchain, which this machine
does not have. `make phone` on such a machine adds it.

## Limits of this port as it stands

- Nothing here has been compiled or run: this workspace has no aarch64 toolchain (no clang for XNU, no
  edk2 for the UEFI). `tools/hakios-config.py check`, `tools/boot-args.py --check` and
  `tools/hakios-device.py check mondrian` pass, which is what can be checked without a compiler.
- The UEFI platform's vendor driver list (`Include/*.inc`) is no longer marble's: it is generated by
  `uefi/make-includes.py` from the list files that come out of this phone's own `uefi` partition (67
  `QcomPkg` drivers, 56 raw files including the K60's `Panel_M11a_42_02_0a_amoled_dsc_cmd.xml`). The
  drivers themselves cannot be published, so the extraction is a step of the build
  (`uefi/files/Binaries/mondrian/README.md`). `uefi/files/Binaries/mondrian/README.md`
  says so, and the build fails loudly if a listed file is absent.
- `uefi/files/Platforms/Xiaomi/mondrianPkg/Library/MemoryMapLib/MemoryMapLib.c` is written from the
  K60's own reserved memory rather than copied from marble, because marble's map puts `Display Demura`
  at 0xa1400000, which on this phone is inside `adsp@0x9fd00000`. The firmware's own rows (UEFI FD,
  stacks, heaps) keep the cape family's addresses, which are what `mondrian.toml` promises.
- The device tree HakiOS boots with, `prebuilt/device-tree.dtb`, is the phone's `/sys/firmware/fdt`: the
  SoC's tree with the board's overlay already merged by the bootloader, which is exactly what this phone
  hands a kernel. `tools/pull-fdt.sh` refetches it from a rooted phone; `tools/merge-dtbo.sh` reproduces it
  from `vendor_boot.img` + `dtbo.img` when no phone is at hand (it needs `fdtoverlay`, which is not part of
  this tree).
