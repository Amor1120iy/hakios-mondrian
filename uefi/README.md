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

## Building it on Windows, with no Visual Studio

This port's UEFI was built this way: a plain Windows 10/11 box, clang from the LLVM release archive, Python
3.11 in a folder, and no Visual Studio at all. Mu-Silicium's build script looks for
`$(CLANG_BIN)mingw32-make.exe`; when it finds one it builds as a "mingw32 host" and stops looking for
Visual Studio. That is the whole trick.

Layout used (any paths work, these are the ones that were tested):

```
D:/toolchain/clangbin/          clang.exe clang-cl.exe lld.exe lld-link.exe ld.lld.exe
                                llvm-ar.exe llvm-lib.exe llvm-objcopy.exe llvm-objdump.exe
                                llvm-size.exe llvm-readobj.exe llvm-rc.exe, and rc.exe (a copy of llvm-rc.exe)
                                mingw32-make.exe  (GNU make 3.81 renamed; its libiconv2.dll/libintl3.dll beside it)
D:/toolchain/py311/             Python 3.11 embeddable, `#import site` uncommented in python311._pth,
                                pip install coloredlogs "edk2-pytool-library~=0.23.17"
                                "edk2-pytool-extensions~=0.31.2" antlr4-python3-runtime==4.13.2 regex pefile
```

Then, from the Mu-Silicium tree:

```sh
export CLANG_BIN="D:/toolchain/clangbin/"
export PYTHONUTF8=1
export PYTHONPATH="$PWD/Mu_Basecore/BaseTools/Source/Python"
export PATH="/d/toolchain/clangbin:/d/toolchain/py311:/d/toolchain/py311/Scripts:$PATH"

python Platforms/Xiaomi/mondrianPkg/DeviceBuild.py --update TARGET=RELEASE   # once: pulls iasl, nasm, ...
printf 'D:/toolchain/clangbin' > Conf/.rc_path                                # see (3) below
python build_uefi.py -d mondrian -r RELEASE
```

Five things had to be dealt with, all of them in the tree (none in the platform's own files):

1. **The `Binaries` submodule.** `DeviceBuild.py` requires it, but this port ships its own `Binaries/mondrian`
   (extracted from the phone, see `files/Binaries/mondrian/README.md`), so the `RequiredSubmodule ("Binaries", True)`
   line is removed. Without that, stuart stops at "destination path ... already exists and is not an empty directory".
2. **ACPI.** The tables come from another Xiaomi platform that is published, `lisa` (the reference port borrows it
   the same way): `mondrian.dsc:86` and `mondrian.fdf:98` say `lisa/AcpiTables.inf`. `marble` has no ACPI platform
   in `Silicium-ACPI`, so pointing at it stops the build with "File/directory not found in workspace".
3. **`rc.exe`.** The `Windows RC Path Support` plugin asks vswhere for a Windows SDK. There is none. It reads
   `Conf/.rc_path` first, so `printf 'D:/toolchain/clangbin' > Conf/.rc_path` plus `rc.exe` being a copy of
   `llvm-rc.exe` in that folder is enough.
4. **BaseTools' own imports.** `build.py`, `Trim.py` and friends do `import Common...` / `import AutoGen...` and
   rely on `edksetup` having put `BaseTools/Source/Python` on `sys.path`. Without it the build stops at
   "ModuleNotFoundError: No module named 'AutoGen'" (and later at `Trim`). Either export `PYTHONPATH` (above) or
   put the parent directory of each script on `sys.path` at the top of the script; both were done here, because
   the makefiles spawn `Trim` as a separate process.
5. **Locale.** With a Chinese Windows the build report dies in `UnicodeDecodeError: 'gbk' codec can't decode`,
   which then fails the `Fd Size Report Generator` post-build plugin even though the FD is already written.
   `PYTHONUTF8=1` fixes it.

What it produced (2026-11-08):

```
Build/mondrianPkg/RELEASE_CLANGPDB/FV/SILICIUM_UEFI.fd   3,145,728 bytes (= FD_SIZE 0x300000)
  sha256 b19f15227ef96eaf216a9341f70524b36b00402340d79b972a9595d112053efb
```

`BootShim.bin` for it (176 bytes, `FD_BASE=0xa7100000 FD_SIZE=0x300000 PAYLOAD_BASE=0xf0000000`):

```sh
cd BootShim && mingw32-make -B REQUIRES_KERNEL_HEADER=1 FD_BASE=0xa7100000 FD_SIZE=0x300000 \
    TARGET=aarch64-linux-gnu CC=clang OBJCOPY=llvm-objcopy \
    CFLAGS="--target=aarch64-linux-gnu -DPAYLOAD_BASE=0xf0000000"
```

and the boot image, with those two and the phone's own tree (see `../prebuilt/README.md`):

```sh
py mkxnuimg.py -d mondrian      # -> xnu-mondrian.img, 1,490,944 bytes
```

That image carries the firmware and the shim; it does **not** carry XNU yet, because the kernel has to be built
with the Apple toolchain this Windows box does not have. `make phone` on a machine that can build `hakios-kernel`
adds it (the shim copies the payload to `0xf0000000`).
