//! List subaccounts for the signing address.
//!
//! Queries all subaccounts and prints their names and addresses.
//! Optionally creates a new subaccount when HL_CREATE_SUB is set.
//!
//! Usage:
//!   HL_KEY=<hex> zig build example-sub_account
//!   HL_KEY=<hex> HL_CREATE_SUB=mybot zig build example-sub_account
//!   HL_KEY=<hex> HL_TESTNET=1 zig build example-sub_account

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

    const addr = eip712.addressToHex(signer.address);
    std.debug.print("Account: {s}  chain: {s}\n\n", .{
        &addr,
        if (is_testnet) "testnet" else "mainnet",
    });

    // ── Optionally create ────────────────────────────────────────
    if (std.process.getEnvVarOwned(allocator, "HL_CREATE_SUB")) |name| {
        defer allocator.free(name);
        std.debug.print("Creating sub-account \"{s}\"...\n", .{name});
        const nonce: u64 = @intCast(std.time.milliTimestamp());
        var result = try client.createSubAccount(signer, .{ .name = name }, nonce, null, null);
        defer result.deinit();
        std.debug.print("{s}\n\n", .{result.body});
    } else |_| {}

    // ── List ─────────────────────────────────────────────────────
    var subs = try client.getSubaccounts(&addr);
    defer subs.deinit();

    if (subs.value.len == 0) {
        std.debug.print("No sub-accounts.\n", .{});
        std.debug.print("Set HL_CREATE_SUB=<name> to create one.\n", .{});
        return;
    }

    std.debug.print("Sub-accounts ({d}):\n", .{subs.value.len});
    for (subs.value) |sub| {
        std.debug.print("  {s: <20} {s}\n", .{ sub.name, sub.subAccountUser });
    }
}
