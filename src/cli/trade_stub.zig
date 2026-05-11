const std = @import("std");
const hlz = @import("hlz");
const runtime = hlz.runtime;

pub const Config = struct {
    chain: hlz.hypercore.signing.Chain = .mainnet,
    key_hex: ?[]const u8 = null,
    address: ?[]const u8 = null,
};

pub fn run(_: std.mem.Allocator, _: Config, _: []const u8) !void {
    std.Io.File.stdout().writeStreamingAll(
        runtime.io(),
        "Trading terminal is a separate binary. Install hlz-terminal and run: hlz-terminal [COIN]\n",
    ) catch {};
    return error.NotAvailable;
}
