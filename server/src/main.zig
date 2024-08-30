const std = @import("std");

const net = std.net;
const posix = std.posix;

pub fn main() !void {
    var address = net.Address.initIp4(.{ 127, 0, 0 , 1 }, 8080);

    const socket = try posix.socket(address.any.family, posix.SOCK.DGRAM | posix.SOCK.CLOEXEC | posix.SOCK.NONBLOCK, posix.IPPROTO.UDP);

    var sock_length = address.getOsSockLen();
    try posix.bind(socket, &address.any, sock_length);
    std.debug.print("{}\n", .{address});
    try posix.getsockname(socket, &address.any, &sock_length);

    const timeout_ms = 10 * 1000;
    var fds: [1]posix.pollfd = .{.{.events = posix.POLL.IN, .fd = socket, .revents = 0}};

    // TODO: make this dynamic
    const size = 1024;
    var buffer: [size]u8 = .{0} ** size;

    while (true) {
        const rc = posix.poll(&fds, timeout_ms) catch |err| switch (err) {
            error.SystemResources, error.NetworkSubsystemFailed, error.Unexpected => blk: {
                std.debug.print("Poll in main loop failed: {s}\n", .{@errorName(err)});
                break :blk 0;
            }
        };

        if (rc < 0) {
            std.debug.print("issues\n", .{});
        } else {
           if (rc & posix.POLL.IN != 0) {
               _ = try posix.recv(fds[0].fd, &buffer, 0);
               std.debug.print("buffer: {s}", .{buffer});
           }
        }
    }
}

//Packet Payload {
  //Frame (8..) ...,
//}
//Frame {
  //Frame Type (i),
  //Type-Dependent Fields (..),
//}
