#!/usr/bin/env python3
"""Apply the driver patches this port needs to the .efi files UEFIReader gave back.

The vendor's drivers are the phone's own, unpatched. Two of the patches the reference phone's copies carry are
found by *proving* the target in the binary rather than by pasting bytes from a diff, so this script can be run
on a new extraction and either patch or say plainly that it could not:

  ButtonsDxe  `mov w8, #0x102` (the special Qcom key code) becomes `mov w8, #0xD` (Enter), so the power button
              is Enter in the UEFI menu. Proven: exactly one such instruction in .text, and it sits in the
              branch that substitutes the code, next to `cmp w1, #1` / `b.ne`.

The rest are listed with what they touch but are NOT applied: they are data or flags whose meaning cannot be
proven from the image alone, and a wrong byte there is a board that does not come up. Do them by hand, with the
source of truth being the same driver built from a Mu-Silicium tree (see uefi/files/Binaries/mondrian/README.md):

  DALSYSDxe    cache coherence for UFS
  TzDxeLA      the Global TZ Applet Variable, FALSE -> TRUE
  UsbConfigDxe remove the USB deinit from the ExitBootServices event
  UsbMsdDxe    removable -> non-removable

usage: py uefi/patch-drivers.py BINARIES_DIR [--dry-run]
       BINARIES_DIR is the one holding QcomPkg/ (Mu-Silicium/Binaries/mondrian).
"""
import argparse
import os
import struct
import sys

MOVZ_W8_0X102 = 0x52802048          # mov w8, #0x102
MOVZ_W8_0X0D = 0x528001A8           # mov w8, #0x0d  (imm16 = 0x0d, Rd = 8)


def text_section(path):
    d = open(path, 'rb').read()
    if d[:2] != b'MZ':
        raise SystemExit('%s: not a PE' % path)
    pe = struct.unpack_from('<I', d, 0x3c)[0]
    nsec = struct.unpack_from('<H', d, pe + 6)[0]
    opt = struct.unpack_from('<H', d, pe + 20)[0]
    base = pe + 24 + opt
    for i in range(nsec):
        off = base + i * 40
        name = d[off:off + 8].rstrip(b'\0').decode('ascii', 'replace')
        if name == '.text':
            vsize, vaddr, rsize, raddr = struct.unpack_from('<IIII', d, off + 8)
            return d, raddr, min(rsize, vsize)
    raise SystemExit('%s: no .text' % path)


def patch_buttons(path, dry):
    d, raddr, size = text_section(path)
    hits = [i for i in range(raddr, raddr + size - 3, 4) if struct.unpack_from('<I', d, i)[0] == MOVZ_W8_0X102]
    if len(hits) != 1:
        return False, '%d matches of mov w8, #0x102 (want exactly one); left alone' % len(hits)
    off = hits[0]
    if dry:
        return True, 'would patch the key code at %#x: mov w8, #0x102 -> mov w8, #0xd' % off
    blob = bytearray(d)
    struct.pack_into('<I', blob, off, MOVZ_W8_0X0D)
    open(path, 'wb').write(bytes(blob))
    return True, 'key code at %#x: mov w8, #0x102 -> mov w8, #0xd (power button is Enter)' % off


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('binaries')
    ap.add_argument('--dry-run', action='store_true')
    a = ap.parse_args()

    buttons = os.path.join(a.binaries, 'QcomPkg', 'Drivers', 'ButtonsDxe', 'ButtonsDxe.efi')
    if os.path.exists(buttons):
        ok, why = patch_buttons(buttons, a.dry_run)
        print('ButtonsDxe: %s%s' % ('ok: ' if ok else 'skip: ', why))
    else:
        print('ButtonsDxe: %s is not there' % buttons)

    for name, what in (
            ('DALSYSDxe', 'cache coherence for UFS'),
            ('TzDxeLA', 'Global TZ Applet Variable FALSE->TRUE'),
            ('UsbConfigDxe', 'no USB deinit at ExitBootServices'),
            ('UsbMsdDxe', 'removable -> non-removable')):
        print('%s: not applied (%s) - see the header of this file' % (name, what))
    return 0


if __name__ == '__main__':
    sys.exit(main())
