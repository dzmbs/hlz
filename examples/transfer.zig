//! Send USDC to an address.
//!
//! Sends 1 USDC to the zero address for demonstration. Transfers on
//! Hyperliquid are free and instant — no gas fees.
//!
//! Usage:
//!   HL_KEY=<hex> zig build example-transfer
//!   HL_KEY=<hex> HL_TESTNET=1 zig build example-transfer

const std = @import("std");
const hlz = @import("hlz");

const Signer = hlz.crypto.signer.Signer;
const Client = hlz.hypercore.client.Client;
const eip712 = hlz.crypto.eip712;

fn fatal(comptime fmt: []const u8, args: anytype) noreturn {
    std.debug.print(fmt ++ "\n", args);
    std.process.exit(1);
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const key_hex = std.process.getEnvVarOwned(allocator, "HL_KEY") catch
        fatal("Set HL_KEY to your private key (hex)", .{});
    defer allocator.free(key_hex);

    const key = if (std.mem.startsWith(u8, key_hex, "0x")) key_hex[2..] else key_hex;
    const signer = Signer.fromHex(key) catch fatal("Invalid private key", .{});

    const is_testnet = if (std.process.getEnvVarOwned(allocator, "HL_TESTNET")) |v| blk: {
        allocator.free(v);
        break :blk true;
    } else |_| false;
    var client = if (is_testnet) Client.testnet(allocator) else Client.mainnet(allocator);
    defer client.deinit();

    const destination = Client.parseAddress("0x0000000000000000000000000000000000000000") catch unreachable;
    const from = eip712.addressToHex(signer.address);

    std.debug.print("From:   {s}\n", .{&from});
    std.debug.print("To:     0x0000...0000\n", .{});
    std.debug.print("Amount: 1 USDC\n", .{});
    std.debug.print("Chain:  {s}\n\n", .{if (is_testnet) "testnet" else "mainnet"});

    const nonce: u64 = @intCast(std.time.milliTimestamp());
    var result = try client.sendUsdc(signer, destination, "1", nonce);
    defer result.deinit();

    std.debug.print("{s}\n", .{result.body});
}
