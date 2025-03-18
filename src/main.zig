const std = @import("std");

const padding = [64]u8{ 0x80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

fn read_file(alloc: std.mem.Allocator, path: []const u8) ![]u8 {
    const input_file = try std.fs.cwd().openFile(path, .{});
    defer input_file.close();

    const file_stat = try input_file.stat();

    return try input_file.readToEndAlloc(alloc, file_stat.size);
}

fn F(x: u32, y: u32, z: u32) u32 {
    return (x & y) | ((~x) & z);
}

fn G(x: u32, y: u32, z: u32) u32 {
    return (x & z) | (y & (~z));
}

fn H(x: u32, y: u32, z: u32) u32 {
    return x ^ y ^ z;
}

fn I(x: u32, y: u32, z: u32) u32 {
    return y ^ (x | (~z));
}

fn mix(comptime f: fn (u32, u32, u32) u32, a: *u32, b: u32, c: u32, d: u32, X_k: u32, s: u32, T_i: u32) void {
    a.* +%= f(b, c, d) +% X_k +% T_i;
    a.* = std.math.rotl(u32, a.*, s);
    a.* +%= b;
}

fn md5_hash(alloc: std.mem.Allocator, data: []const u8) ![16]u8 {
    const offset = data.len % 64;
    var extra: usize = 56;

    // If we will underflow, add an extra block
    if (offset >= 56) {
        extra += 64;
    }
    extra -= offset;
    const padded_len = data.len + extra;

    // Add 8 for the legth of our message
    var padded_data = try std.ArrayList(u8).initCapacity(alloc, padded_len + 8);
    defer padded_data.deinit();

    // Add our data
    try padded_data.appendSlice(data[0..]);

    // Pad with a 1 followed by 0s
    try padded_data.appendSlice(padding[0..(padded_len - data.len)]);

    // Append length as 64 bit number
    const low_order_word: u32 = @intCast((data.len * 8) & 0xffffffff);
    const high_order_word: u32 = @intCast(((data.len * 8) >> 32) & 0xffffffff);

    try padded_data.writer().writeInt(u32, low_order_word, .little);
    try padded_data.writer().writeInt(u32, high_order_word, .little);

    // Create hash buffer
    var buffer = [4]u32{
        0x67452301,
        0xefcdab89,
        0x98badcfe,
        0x10325476,
    };

    // Number of 32-bit words
    const N = padded_data.items.len / 4;

    // Process each 16-word block
    var X = std.mem.zeroes([16]u32);
    for (0..(N / 16)) |i| {
        // Copy block i into X
        for (0..16) |j| {
            // We read 4 bytes into a 32 bit integer
            const start = i * 64 + j * 4;
            const end = start + 4;

            X[j] = std.mem.readInt(u32, @ptrCast(padded_data.items[start..end]), .little);
        }

        var A = buffer[0];
        var B = buffer[1];
        var C = buffer[2];
        var D = buffer[3];

        // Round 1
        mix(F, &A, B, C, D, X[0], 7, 0xd76aa478);
        mix(F, &D, A, B, C, X[1], 12, 0xe8c7b756);
        mix(F, &C, D, A, B, X[2], 17, 0x242070db);
        mix(F, &B, C, D, A, X[3], 22, 0xc1bdceee);

        mix(F, &A, B, C, D, X[4], 7, 0xf57c0faf);
        mix(F, &D, A, B, C, X[5], 12, 0x4787c62a);
        mix(F, &C, D, A, B, X[6], 17, 0xa8304613);
        mix(F, &B, C, D, A, X[7], 22, 0xfd469501);

        mix(F, &A, B, C, D, X[8], 7, 0x698098d8);
        mix(F, &D, A, B, C, X[9], 12, 0x8b44f7af);
        mix(F, &C, D, A, B, X[10], 17, 0xffff5bb1);
        mix(F, &B, C, D, A, X[11], 22, 0x895cd7be);

        mix(F, &A, B, C, D, X[12], 7, 0x6b901122);
        mix(F, &D, A, B, C, X[13], 12, 0xfd987193);
        mix(F, &C, D, A, B, X[14], 17, 0xa679438e);
        mix(F, &B, C, D, A, X[15], 22, 0x49b40821);

        // Round 2
        mix(G, &A, B, C, D, X[1], 5, 0xf61e2562);
        mix(G, &D, A, B, C, X[6], 9, 0xc040b340);
        mix(G, &C, D, A, B, X[11], 14, 0x265e5a51);
        mix(G, &B, C, D, A, X[0], 20, 0xe9b6c7aa);

        mix(G, &A, B, C, D, X[5], 5, 0xd62f105d);
        mix(G, &D, A, B, C, X[10], 9, 0x2441453);
        mix(G, &C, D, A, B, X[15], 14, 0xd8a1e681);
        mix(G, &B, C, D, A, X[4], 20, 0xe7d3fbc8);

        mix(G, &A, B, C, D, X[9], 5, 0x21e1cde6);
        mix(G, &D, A, B, C, X[14], 9, 0xc33707d6);
        mix(G, &C, D, A, B, X[3], 14, 0xf4d50d87);
        mix(G, &B, C, D, A, X[8], 20, 0x455a14ed);

        mix(G, &A, B, C, D, X[13], 5, 0xa9e3e905);
        mix(G, &D, A, B, C, X[2], 9, 0xfcefa3f8);
        mix(G, &C, D, A, B, X[7], 14, 0x676f02d9);
        mix(G, &B, C, D, A, X[12], 20, 0x8d2a4c8a);

        // Round 3
        mix(H, &A, B, C, D, X[5], 4, 0xfffa3942);
        mix(H, &D, A, B, C, X[8], 11, 0x8771f681);
        mix(H, &C, D, A, B, X[11], 16, 0x6d9d6122);
        mix(H, &B, C, D, A, X[14], 23, 0xfde5380c);

        mix(H, &A, B, C, D, X[1], 4, 0xa4beea44);
        mix(H, &D, A, B, C, X[4], 11, 0x4bdecfa9);
        mix(H, &C, D, A, B, X[7], 16, 0xf6bb4b60);
        mix(H, &B, C, D, A, X[10], 23, 0xbebfbc70);

        mix(H, &A, B, C, D, X[13], 4, 0x289b7ec6);
        mix(H, &D, A, B, C, X[0], 11, 0xeaa127fa);
        mix(H, &C, D, A, B, X[3], 16, 0xd4ef3085);
        mix(H, &B, C, D, A, X[6], 23, 0x4881d05);

        mix(H, &A, B, C, D, X[9], 4, 0xd9d4d039);
        mix(H, &D, A, B, C, X[12], 11, 0xe6db99e5);
        mix(H, &C, D, A, B, X[15], 16, 0x1fa27cf8);
        mix(H, &B, C, D, A, X[2], 23, 0xc4ac5665);

        // Round 4
        mix(I, &A, B, C, D, X[0], 6, 0xf4292244);
        mix(I, &D, A, B, C, X[7], 10, 0x432aff97);
        mix(I, &C, D, A, B, X[14], 15, 0xab9423a7);
        mix(I, &B, C, D, A, X[5], 21, 0xfc93a039);

        mix(I, &A, B, C, D, X[12], 6, 0x655b59c3);
        mix(I, &D, A, B, C, X[3], 10, 0x8f0ccc92);
        mix(I, &C, D, A, B, X[10], 15, 0xffeff47d);
        mix(I, &B, C, D, A, X[1], 21, 0x85845dd1);

        mix(I, &A, B, C, D, X[8], 6, 0x6fa87e4f);
        mix(I, &D, A, B, C, X[15], 10, 0xfe2ce6e0);
        mix(I, &C, D, A, B, X[6], 15, 0xa3014314);
        mix(I, &B, C, D, A, X[13], 21, 0x4e0811a1);

        mix(I, &A, B, C, D, X[4], 6, 0xf7537e82);
        mix(I, &D, A, B, C, X[11], 10, 0xbd3af235);
        mix(I, &C, D, A, B, X[2], 15, 0x2ad7d2bb);
        mix(I, &B, C, D, A, X[9], 21, 0xeb86d391);

        buffer[0] +%= A;
        buffer[1] +%= B;
        buffer[2] +%= C;
        buffer[3] +%= D;

        // Zero sensitive information
        X = std.mem.zeroes([16]u32);
    }

    return std.mem.toBytes(buffer);
}

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    // Initiate allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const file_contents = try read_file(alloc, "./build.zig");
    defer alloc.free(file_contents);

    const hash = try md5_hash(alloc, file_contents);
    try stdout.print("{s}\n", .{std.fmt.fmtSliceHexLower(&hash)});

    try bw.flush();
}

const TestCase = std.meta.Tuple(&.{ []const u8, []const u8 });

test "test md5" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const cases = [_]TestCase{
        .{ "", "d41d8cd98f00b204e9800998ecf8427e" },
        .{ "a", "0cc175b9c0f1b6a831c399e269772661" },
        .{ "abc", "900150983cd24fb0d6963f7d28e17f72" },
        .{ "message digest", "f96b697d7cb7938d525a2f31aaf161d0" },
        .{ "abcdefghijklmnopqrstuvwxyz", "c3fcd3d76192e4007dfb496cca67e13b" },
        .{ "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789", "d174ab98d277d9f5a5611c2c9f419d9f" },
        .{ "12345678901234567890123456789012345678901234567890123456789012345678901234567890", "57edf4a22be3c955ac49da2e2107b67a" },
    };

    for (cases) |case| {
        const hash = try md5_hash(alloc, case[0]);
        const hex = std.fmt.bytesToHex(&hash, .lower);
        try std.testing.expectEqualStrings(case[1], &hex);
    }
}
