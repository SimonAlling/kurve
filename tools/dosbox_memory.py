# DOSBox emulates the guest's RAM as one contiguous block in its own (host) memory, so a guest address is just an offset from the start of that block.

# Like a real PC BIOS, DOSBox puts its (hardcoded) BIOS date at guest address 0xFFFF5.
BIOS_DATE = b"01/01/92"
GUEST_ADDRESS_OF_BIOS_DATE = 0xFFFF5

# Where the original game stores the state that we're concerned with.
GUEST_ADDRESS_OF_GAME_STATE = 0xCFE6


def find_base_address(dosbox_pid: int) -> int | None:
    """
    Returns the host address of the game state, i.e. what the relative addresses in the gdb program are relative to.
    """
    guest_ram = find_guest_ram(dosbox_pid)
    if guest_ram is None:
        return None
    return guest_ram + GUEST_ADDRESS_OF_GAME_STATE


def find_guest_ram(dosbox_pid: int) -> int | None:
    """
    Returns the host address where DOSBox's emulated RAM starts, by searching DOSBox's memory for the BIOS date.
    """
    with (
        open(f"/proc/{dosbox_pid}/maps") as maps,
        open(f"/proc/{dosbox_pid}/mem", "rb", buffering=0) as mem,
    ):
        for line in maps:
            # Each line describes a memory region, e.g.:
            #
            #     7fffac5f8000-7fffad5f9000 rw-p 00000000 00:00 0
            #
            address_range, permissions, *_ = line.split()
            if not permissions.startswith("rw"):
                continue  # The guest RAM is writable, so this can't be it.
            start, end = (int(x, 16) for x in address_range.split("-"))
            try:
                mem.seek(start)
                region = mem.read(end - start)
            except OSError:
                continue  # Some regions just can't be read.
            offset_in_region = region.find(BIOS_DATE)
            if offset_in_region != -1:
                host_address_of_bios_date = start + offset_in_region
                return host_address_of_bios_date - GUEST_ADDRESS_OF_BIOS_DATE
    return None


def read_memory(dosbox_pid: int, host_address: int, number_of_bytes: int) -> bytes:
    with open(f"/proc/{dosbox_pid}/mem", "rb", buffering=0) as mem:
        mem.seek(host_address)
        return mem.read(number_of_bytes)
