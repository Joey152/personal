const std = @import("std");
const linux = std.os.linux;
const syscall0 = linux.syscall0;
const syscall1 = linux.syscall1;
const syscall2 = linux.syscall2;
const syscall3 = linux.syscall3;
const syscall4 = linux.syscall4;
const syscall5 = linux.syscall5;
const syscall6 = linux.syscall6;
const syscall7 = linux.syscall7;

pub fn io_uring_setup(entries: u32, p: *linux.io_uring_params) usize {
    return syscall2(.io_uring_setup, entries, @intFromPtr(p));
}

pub fn io_uring_enter(fd: usize, to_submit: u32, min_complete: u32, flags: u32, arg: ?[*]linux.io_uring_getevents_arg, argz: usize) usize {
    std.debug.assert(flags & linux.IORING_ENTER_EXT_ARG == linux.IORING_ENTER_EXT_ARG);
    return syscall6(.io_uring_enter, fd, to_submit, min_complete, flags, @intFromPtr(arg), argz);
}

pub fn mmap(address: ?[*]u8, length: usize, prot: usize, flags: linux.MAP, fd: usize, offset: usize) usize {
    if (@hasField(linux.SYS, "mmap2")) {
        // Make sure the offset is also specified in multiples of page size
        if ((offset & (linux.MMAP2_UNIT - 1)) != 0)
            return @bitCast(-@as(isize, @intFromEnum(linux.E.INVAL)));

        return syscall6(
            .mmap2,
            @intFromPtr(address),
            length,
            prot,
            @as(u32, @bitCast(flags)),
            fd,
            offset,
        );
    } else {
        return syscall6(
            .mmap,
            @intFromPtr(address),
            length,
            prot,
            @as(u32, @bitCast(flags)),
            fd,
            offset,
        );
    }
}

pub fn munmap(address: [*]const u8, length: usize) usize {
    return syscall2(.munmap, @intFromPtr(address), length);
}
