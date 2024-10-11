const std = @import("std");
const syscall = @import("./syscall.zig");

const net = std.net;
const posix = std.posix;
const assert = std.debug.assert;
const linux = std.os.linux;

pub fn main() !void {
    var address = net.Address.initIp4(.{ 127, 0, 0 , 1 }, 8080);

    var ring = linux.io_uring_params {
        .flags = linux.IORING_SETUP_IOPOLL,
        .sq_thread_cpu = 0,
        .sq_thread_idle = 0,

        // the rest are filled in by io_uring_setup
        .sq_entries = 0,
        .cq_entries = 0,
        .features = 0,
        .wq_fd = 0,
        .resv = .{0} ** 3,
        .sq_off = .{
            .head = 0,
            .tail = 0,
            .ring_mask = 0,
            .ring_entries = 0,
            .flags = 0,
            .dropped = 0,
            .array = 0,
            .resv1 = 0,
            .user_addr = 0,
        },
        .cq_off = .{
            .head = 0,
            .tail = 0,
            .ring_mask = 0,
            .ring_entries = 0,
            .overflow = 0,
            .cqes = 0,
            .flags = 0,
            .resv = 0,
            .user_addr = 0,
        },
    };
    const ring_fd = syscall.io_uring_setup(10, &ring);

    const must_have_features = linux.IORING_FEAT_SINGLE_MMAP;
    if (ring.features & must_have_features != must_have_features) {
        std.log.err("Linux version is not compatible does not have all io_uring features: {}\n", .{ring.features});
        return;
    }

    std.debug.print("{}\n", .{ring});

    // linux.io_uring_enter(ring, 1, 0, );

    const socket = try posix.socket(address.any.family, posix.SOCK.DGRAM | posix.SOCK.CLOEXEC | posix.SOCK.NONBLOCK, posix.IPPROTO.UDP);

    // Map both sq and cq with IORING_FEAT_SINGLE_MMAP
    const sring_size = ring.sq_off.array + ring.sq_entries * @sizeOf(u32);
    const cring_size = ring.cq_off.cqes + ring.cq_entries * @sizeOf(linux.io_uring_cqe);
    const max = @max(sring_size, cring_size);

    const queue = syscall.mmap(null, max, linux.PROT.READ | linux.PROT.WRITE, .{.TYPE = .SHARED, .POPULATE = true}, ring_fd, linux.IORING_OFF_SQ_RING);
    switch (linux.E.init(queue)) {
        .SUCCESS => {},
        else => |err| std.debug.panic("Unable to recover from mmap: {}", .{err}),
    }

    const sqe = syscall.mmap(null, ring.sq_entries * @sizeOf(linux.io_uring_sqe), linux.PROT.READ | linux.PROT.WRITE, .{.TYPE = .SHARED, .POPULATE = true}, ring_fd, linux.IORING_OFF_SQES);
    switch (linux.E.init(sqe)) {
        .SUCCESS => {},
        else => |err| std.debug.panic("Unable to recover from mmap: {}", .{err}),
    }

    var accept: linux.io_uring_sqe = undefined;
    accept.prep_socket(address.any.family, posix.SOCK.DGRAM | posix.SOCK.CLOEXEC | posix.SOCK.NONBLOCK, posix.IPPROTO.UDP, 0);
    //syscall.io_uring_enter(ring_fd, 0, 1, );

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
                std.log.err("Poll in main loop failed: {s}\n", .{@errorName(err)});
                break :blk 0;
            }
        };

        if (rc < 0) {
            std.debug.print("issues\n", .{});
        } else {
            if (rc & posix.POLL.IN != 0) {
                const readSize = posix.recv(fds[0].fd, &buffer, 0) catch |err| switch (err) {
                    error.WouldBlock,
                    error.ConnectionRefused,
                    error.SystemResources,
                    error.ConnectionResetByPeer,
                    error.ConnectionTimedOut,
                    error.SocketNotBound,
                    error.MessageTooBig, // TODO: should handle this special case
                    error.NetworkSubsystemFailed,
                    error.SocketNotConnected,
                    error.Unexpected => blk: {
                        std.log.err("Read failed in main loop: {s}\n", .{@errorName(err)});
                        break :blk 0;
                    }
                };
                _ = readSize;
                //std.debug.print("buffer, size: {s}, {}\n", .{buffer, readSize});
                if (buffer[0] & 0xc0 == 0xc0) {
                    var packet = LongHeaderPacket{
                        .packetType = buffer[0],
                        .version = std.mem.readInt(u32, buffer[1..5], .big),
                        .dstConnectionIdLength = undefined,
                        .dstConnectionId = undefined,
                        .srcConnectionIdLength = undefined,
                        .srcConnectionId = undefined,
                    };

                    var p: u32 = 5;
                    packet.dstConnectionIdLength = buffer[p];
                    // TODO: Endpoints that receive a version 1 long header with a value larger than 20 MUST drop the packet
                    p += 1;
                    packet.dstConnectionId = ConnectionId.init(buffer[p..p+packet.dstConnectionIdLength]);
                    p += packet.dstConnectionIdLength;
                    packet.srcConnectionIdLength = buffer[p];
                    p += 1;
                    packet.srcConnectionId = ConnectionId.init(buffer[p..p+packet.srcConnectionIdLength]);

                    std.debug.print("LongHeader: {}\n", .{packet});

                    if (packet.packetType & 0x0 == 0x0) {
                        std.debug.print("Initial packet\n", .{});
                    } else if (packet.packetType & 0x10 == 0x10) {
                        std.debug.print("0-RTT\n", .{});
                    } else if (packet.packetType & 0x20 == 0x20) {
                        std.debug.print("Handshake\n", .{});
                    } else if (packet.packetType & 0x30 == 0x30) {
                        std.debug.print("Retry\n", .{});
                    }
                }
            }
        }
    }
}

const ConnectionId = struct {
    buffer: [20]u8,

    pub fn init(buffer: []u8) ConnectionId {
        assert(buffer.len <= 20);

        var id = ConnectionId{
            .buffer = undefined,
        };
        std.mem.copyForwards(u8, &id.buffer, buffer[0..buffer.len]);

        return id;
    }
};

const LongHeaderPacket = struct {
    // form: 1,
    // fixed: 1,
    // type: u2,
    // specific: u4,
    packetType: u8,
    version: u32,
    dstConnectionIdLength: u8,
    dstConnectionId: ConnectionId,
    srcConnectionIdLength: u8,
    srcConnectionId: ConnectionId,
};

const InitialPacket = struct {
    longHeader: LongHeaderPacket,
};

// Token Length:
// A variable-length integer specifying the length of the Token field, in bytes. This value is 0 if no token is present. Initial packets sent by the server MUST set the
// Token Length field to 0; clients that receive an Initial packet with a non-zero Token Length field MUST either discard the packet or generate a
// connection error of type PROTOCOL_VIOLATION.

// Token:
// The value of the token that was previously provided in a Retry packet or NEW_TOKEN frame; see Section 8.1.

// In order to prevent tampering by version-unaware middleboxes, Initial packets are protected with connection- and version-specific keys (Initial keys)
//  as described in [QUIC-TLS]. This protection does not provide confidentiality or integrity against attackers that can observe packets,
//  but it does prevent attackers that cannot observe packets from spoofing Initial packets.

// Long Header Packet {
//   Header Form (1) = 1,
//   Fixed Bit (1) = 1,
//   Long Packet Type (2),
//   Type-Specific Bits (4),
//   Version (32),
//   Destination Connection ID Length (8),
//   Destination Connection ID (0..160),
//   Source Connection ID Length (8),
//   Source Connection ID (0..160),
//   Type-Specific Payload (..),
// }

// Initial Packet {
//   Header Form (1) = 1,
//   Fixed Bit (1) = 1,
//   Long Packet Type (2) = 0,
//   Reserved Bits (2),
//   Packet Number Length (2),
//   Version (32),
//   Destination Connection ID Length (8),
//   Destination Connection ID (0..160),
//   Source Connection ID Length (8),
//   Source Connection ID (0..160),
//   Token Length (i),
//   Token (..),
//   Length (i),
//   Packet Number (8..32),
//   Packet Payload (8..),
// }

//Packet Payload {
  //Frame (8..) ...,
//}
//Frame {
  //Frame Type (i),
  //Type-Dependent Fields (..),
//}
