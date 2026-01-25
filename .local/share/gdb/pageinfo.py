import gdb
import os
import re
import struct

MAPS_RE = re.compile(
    r"^(?P<start>[0-9a-fA-F]+)-(?P<end>[0-9a-fA-F]+)\s+"
    r"(?P<perms>\S+)\s+"
    r"(?P<offset>[0-9a-fA-F]+)\s+"
    r"(?P<dev>\S+)\s+"
    r"(?P<inode>\d+)"
    r"(?:\s+(?P<path>.*))?$"
)


def _parse_addr(expr: str) -> int:
    # Allows: pageinfo 0x..., pageinfo $rsp, pageinfo &var, etc.
    v = gdb.parse_and_eval(expr)
    return int(v)


def _pid() -> int:
    # Works when debugging a live inferior. For corefiles, pid may be unavailable.
    inf = gdb.selected_inferior()
    if inf is None or inf.pid is None:
        raise gdb.GdbError(
            "No live inferior PID available (are you attached/running?)."
        )
    return int(inf.pid)


def _read_maps(pid: int):
    entries = []
    with open(f"/proc/{pid}/maps", "r", encoding="utf-8") as f:
        for line in f:
            m = MAPS_RE.match(line.rstrip("\n"))
            if not m:
                continue
            start = int(m.group("start"), 16)
            end = int(m.group("end"), 16)
            perms = m.group("perms")
            offset = int(m.group("offset"), 16)
            dev = m.group("dev")
            inode = int(m.group("inode"))
            path = (m.group("path") or "").strip()
            entries.append((start, end, perms, offset, dev, inode, path))
    return entries


def _find_mapping(entries, addr: int):
    for e in entries:
        if e[0] <= addr < e[1]:
            return e
    return None


def _read_pagemap_entry(pid: int, vaddr: int) -> int:
    page_size = os.sysconf("SC_PAGE_SIZE")
    vpn = vaddr // page_size
    off = vpn * 8
    with open(f"/proc/{pid}/pagemap", "rb") as f:
        f.seek(off)
        data = f.read(8)
        if len(data) != 8:
            raise gdb.GdbError("Short read from pagemap.")
        return struct.unpack("<Q", data)[0]


def _decode_pagemap(entry: int):
    present = bool((entry >> 63) & 1)
    swapped = bool((entry >> 62) & 1)
    file_page = bool((entry >> 61) & 1)
    soft_dirty = bool((entry >> 55) & 1)
    pfn = entry & ((1 << 55) - 1)
    return present, swapped, file_page, soft_dirty, pfn


class PageInfo(gdb.Command):
    """pageinfo EXPR
    Print mapping information (perms/file/offset) and optional pagemap status for address EXPR.
    Examples:
      pageinfo 0x7f...       pageinfo $rsp      pageinfo &some_var
    """

    def __init__(self):
        super(PageInfo, self).__init__("pageinfo", gdb.COMMAND_STATUS)

    def invoke(self, arg, from_tty):
        arg = arg.strip()
        if not arg:
            raise gdb.GdbError("Usage: pageinfo EXPR")

        addr = _parse_addr(arg)
        pid = _pid()

        gdb.write(f"Address     : 0x{addr:x}\n")
        gdb.write(f"Inferior PID: {pid}\n")

        entries = _read_maps(pid)
        m = _find_mapping(entries, addr)
        if not m:
            gdb.write("Mapping     : <not mapped>\n")
            return

        start, end, perms, offset, dev, inode, path = m
        gdb.write("=== /proc/<pid>/maps ===\n")
        gdb.write(f"Region      : 0x{start:x}-0x{end:x}  (size {end-start} bytes)\n")
        gdb.write(f"Perms       : {perms}\n")
        gdb.write(f"Offset      : 0x{offset:x}\n")
        gdb.write(f"Dev/Inode   : {dev} / {inode}\n")
        gdb.write(f"Path        : {path if path else '(anonymous/special)'}\n")

        gdb.write("=== /proc/<pid>/pagemap ===\n")
        try:
            pm = _read_pagemap_entry(pid, addr)
            present, swapped, file_page, soft_dirty, pfn = _decode_pagemap(pm)
            gdb.write(f"Raw         : 0x{pm:016x}\n")
            gdb.write(f"present     : {present}\n")
            gdb.write(f"swapped     : {swapped}\n")
            gdb.write(f"file_page   : {file_page}\n")
            gdb.write(f"soft_dirty  : {soft_dirty}\n")
            gdb.write(f"pfn_or_swap : {pfn}\n")
            if present and pfn != 0:
                page_size = os.sysconf("SC_PAGE_SIZE")
                phys = (pfn * page_size) + (addr % page_size)
                gdb.write(f"phys_est    : 0x{phys:x}\n")
            else:
                gdb.write("phys_est    : <not available>\n")
        except PermissionError:
            gdb.write(
                "pagemap      : Permission denied (try running gdb as root / with CAP_SYS_ADMIN)\n"
            )
        except FileNotFoundError:
            gdb.write("pagemap      : Not available on this system\n")
        except Exception as e:
            gdb.write(f"pagemap      : Failed ({e})\n")


PageInfo()
