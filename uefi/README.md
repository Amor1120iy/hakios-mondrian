# UEFI for mondrian

The Redmi K60's platform for HakiOS's UEFI (`uefi/` of the common repository: Mu-Silicium with HakiOS's changes
and banner). It is modelled on `marble` — the Poco F5, Xiaomi's other `PalimaPkg` cape board, the closest published
platform: same SoC package, same BSP family (its raw-file list even names this phone's panel,
`Panel_M11a_42_02_0a_amoled_dsc_cmd.xml`).

What is here, in `files/`:

- `Platforms/Xiaomi/mondrianPkg`: the memory map (`Library/MemoryMapLib`, written from **this phone's** device tree,
  not marble's: marble reserves `Display Demura` at 0xA1400000, which on the K60 is the middle of `adsp@0x9fd00000`),
  the configuration map (generic SM8475), the driver list (`Include/*.inc`), and the FDT blob;
- `Resources/Configs/mondrian.toml` — `[uefi_fd] base = 0xA7100000 size = 0x300000`, `[boot_image] header_version = 4`
  (the K60's own boot.img is v4, so `mkxnuimg.py` packs the same way);
- `Resources/DTBs/mondrian.dtb` — the phone's vendor_boot tree, the same file as `../prebuilt/device-tree.dtb`;
- `Binaries/mondrian`: the vendor's UEFI drivers, **not tracked**: you make this directory yourself from your
  own phone — `tools/pull-uefi.sh` copies the `uefi` partition out, UEFIReader turns it into the driver tree, and
  `files/Binaries/mondrian/README.md` writes the whole recipe down (it also lists the patches the reference
  phone's copies carry). `Include/*.inc` is generated from the vendor lists that come with that extraction by
  `uefi/make-includes.py`, so the build asks for exactly the drivers this phone has.

```sh
devices/mondrian/uefi/apply.sh     # = uefi/apply.sh mondrian
```

Two things this platform borrows rather than owns, both the way `redwood` borrows `lisa`:

- `SOC_TYPE = 0` (SM8475) with `!include PalimaPkg/PalimaPkg.dsc.inc` — the SM8475 SoC package that `pong` and
  `marble` use;
- `marble/AcpiTables.inf` for the ACPI tables. XNU does not read ACPI, so this only matters for the UEFI shell.

The build and the vendor's drivers: [uefi/README.md](../../../uefi/README.md).

```sh
python3 build_uefi.py -d mondrian -r RELEASE      # → Build/mondrianPkg/RELEASE_CLANGPDB/FV/SILICIUM_UEFI.fd
make prebuilt                                     # copies it, BootShim.bin, the ramdisk and mkbootimg.py here
make phone                                        # → xnu-mondrian.img
```
