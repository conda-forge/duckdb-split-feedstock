# This code is taken from https://github.com/pyinstaller/pyinstaller/blob/061761c1d7a3d3d04aae0e22e20241c1c89552f1/PyInstaller/utils/osx.py#L166
# It was originally licensed under the following license:
#
#-----------------------------------------------------------------------------
# Copyright (c) 2005-2023, PyInstaller Development Team.
#
# Distributed under the terms of the GNU General Public License (version 2
# or later) with exception for distributing the bootloader.
#
# The full license is in the file COPYING.txt, distributed with this software.
#
# SPDX-License-Identifier: (GPL-2.0-or-later WITH Bootloader-exception)
#-----------------------------------------------------------------------------

import math 
import os
import sys

from macholib.MachO import MachO
from macholib.mach_o import (
    LC_BUILD_VERSION,
    LC_CODE_SIGNATURE,
    LC_ID_DYLIB,
    LC_LOAD_DYLIB,
    LC_LOAD_UPWARD_DYLIB,
    LC_LOAD_WEAK_DYLIB,
    LC_PREBOUND_DYLIB,
    LC_REEXPORT_DYLIB,
    LC_RPATH,
    LC_SEGMENT_64,
    LC_SYMTAB,
    LC_VERSION_MIN_MACOSX,
)


def _get_arch_string(header):
    """
    Converts cputype and cpusubtype from mach_o.mach_header_64 into arch string comparible with lipo/codesign.
    The list of supported architectures can be found in man(1) arch.
    """
    # NOTE: the constants below are taken from macholib.mach_o
    cputype = header.cputype
    cpusubtype = header.cpusubtype & 0x0FFFFFFF
    if cputype == 0x01000000 | 7:
        if cpusubtype == 8:
            return 'x86_64h'  # 64-bit intel (haswell)
        else:
            return 'x86_64'  # 64-bit intel
    elif cputype == 0x01000000 | 12:
        if cpusubtype == 2:
            return 'arm64e'
        else:
            return 'arm64'
    elif cputype == 7:
        return 'i386'  # 32-bit intel
    assert False, 'Unhandled architecture!'


def fix_exe_for_code_signing(filename):
    """
    Fixes the Mach-O headers to make code signing possible.

    Code signing on Mac OS does not work out of the box with embedding .pkg archive into the executable.

    The fix is done this way:
    - Make the embedded .pkg archive part of the Mach-O 'String Table'. 'String Table' is at end of the Mac OS exe file,
      so just change the size of the table to cover the end of the file.
    - Fix the size of the __LINKEDIT segment.

    Note: the above fix works only if the single-arch thin executable or the last arch slice in a multi-arch fat
    executable is not signed, because LC_CODE_SIGNATURE comes after LC_SYMTAB, and because modification of headers
    invalidates the code signature. On modern arm64 macOS, code signature is mandatory, and therefore compilers
    create a dummy signature when executable is built. In such cases, that signature needs to be removed before this
    function is called.

    Mach-O format specification: http://developer.apple.com/documentation/Darwin/Reference/ManPages/man5/Mach-O.5.html
    """
    # Estimate the file size after data was appended
    file_size = os.path.getsize(filename)

    # Take the last available header. A single-arch thin binary contains a single slice, while a multi-arch fat binary
    # contains multiple, and we need to modify the last one, which is adjacent to the appended data.
    executable = MachO(filename)
    header = executable.headers[-1]

    # Sanity check: ensure the executable slice is not signed (otherwise signature's section comes last in the
    # __LINKEDIT segment).
    sign_sec = [cmd for cmd in header.commands if cmd[0].cmd == LC_CODE_SIGNATURE]
    assert len(sign_sec) == 0, "Executable contains code signature!"

    # Find __LINKEDIT segment by name (16-byte zero padded string)
    __LINKEDIT_NAME = b'__LINKEDIT\x00\x00\x00\x00\x00\x00'
    linkedit_seg = [cmd for cmd in header.commands if cmd[0].cmd == LC_SEGMENT_64 and cmd[1].segname == __LINKEDIT_NAME]
    assert len(linkedit_seg) == 1, "Expected exactly one __LINKEDIT segment!"
    linkedit_seg = linkedit_seg[0][1]  # Take the segment command entry
    # Find SYMTAB section
    symtab_sec = [cmd for cmd in header.commands if cmd[0].cmd == LC_SYMTAB]
    assert len(symtab_sec) == 1, "Expected exactly one SYMTAB section!"
    symtab_sec = symtab_sec[0][1]  # Take the symtab command entry

    # The string table is located at the end of the SYMTAB section, which in turn is the last section in the __LINKEDIT
    # segment. Therefore, the end of SYMTAB section should be aligned with the end of __LINKEDIT segment, and in turn
    # both should be aligned with the end of the file (as we are in the last or the only arch slice).
    #
    # However, when removing the signature from the executable using codesign under Mac OS 10.13, the codesign utility
    # may produce an invalid file, with the declared length of the __LINKEDIT segment (linkedit_seg.filesize) pointing
    # beyond the end of file, as reported in issue #6167.
    #
    # We can compensate for that by not using the declared sizes anywhere, and simply recompute them. In the final
    # binary, the __LINKEDIT segment and the SYMTAB section MUST end at the end of the file (otherwise, we have bigger
    # issues...). So simply recompute the declared sizes as difference between the final file length and the
    # corresponding start offset (NOTE: the offset is relative to start of the slice, which is stored in header.offset.
    # In thin binaries, header.offset is zero and start offset is relative to the start of file, but with fat binaries,
    # header.offset is non-zero)
    symtab_sec.strsize = file_size - (header.offset + symtab_sec.stroff)
    linkedit_seg.filesize = file_size - (header.offset + linkedit_seg.fileoff)

    # Compute new vmsize by rounding filesize up to full page size.
    page_size = (0x4000 if _get_arch_string(header.header).startswith('arm64') else 0x1000)
    linkedit_seg.vmsize = math.ceil(linkedit_seg.filesize / page_size) * page_size

    # NOTE: according to spec, segments need to be aligned to page boundaries: 0x4000 (16 kB) for arm64, 0x1000 (4 kB)
    # for other arches. But it seems we can get away without rounding and padding the segment file size - perhaps
    # because it is the last one?

    # Write changes
    with open(filename, 'rb+') as fp:
        executable.write(fp)

    # In fat binaries, we also need to adjust the fat header. macholib as of version 1.14 does not support this, so we
    # need to do it ourselves...
    if executable.fat:
        from macholib.mach_o import (FAT_MAGIC, FAT_MAGIC_64, fat_arch, fat_arch64, fat_header)
        with open(filename, 'rb+') as fp:
            # Taken from MachO.load_fat() implementation. The fat header's signature has already been validated when we
            # loaded the file for the first time.
            fat = fat_header.from_fileobj(fp)
            if fat.magic == FAT_MAGIC:
                archs = [fat_arch.from_fileobj(fp) for i in range(fat.nfat_arch)]
            elif fat.magic == FAT_MAGIC_64:
                archs = [fat_arch64.from_fileobj(fp) for i in range(fat.nfat_arch)]
            # Adjust the size in the fat header for the last slice.
            arch = archs[-1]
            arch.size = file_size - arch.offset
            # Now write the fat headers back to the file.
            fp.seek(0)
            fat.to_fileobj(fp)
            for arch in archs:
                arch.to_fileobj(fp)


if __name__ == "__main__":
    fix_exe_for_code_signing(sys.argv[-1])
