//! Place a limit order, query its status, then cancel it.
//!
//! Demonstrates the core trading loop: place → query → cancel.
//! Places a BTC limit buy at $1 (will never fill), verifies it's resting,
//! then cancels by OID.
//!
//! Usage:
//!   HL_KEY=<hex> zig build example-place_order
//!   HL_KEY=<hex> HL_TESTNET=1 zig build example-place_order

const std = @import("std");
const hlz = @import("hlz");

const Signer = hlz.crypto.signer.Signer;
const Decimal = hlz.math.decimal.Decimal;
const types = hlz.hypercore.types;
const Client = hlz.hypercore.client.Client;
const eip712 = hlz.crypto.eip712;

fn fatal(comptime fmt: []const u8, args: anytype) noreturn {
    std.debug.print(fmt ++ "\n", args);
    std.process.exit(1);
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const key_hex = std.process.getEnvVarOwned(allocator, "HL_KEY") catch
        fatal("Set HL_KEY to your private key (hex, with or without 0x)", .{});
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

    // ── Place ────────────────────────────────────────────────────
    // Limit buy 0.001 BTC @ $1 GTC — will rest, never fill.
    const order = types.OrderRequest{
        .asset = 0,
        .is_buy = true,
        .limit_px = Decimal.fromString("1") catch unreachable,
        .sz = Decimal.fromString("0.001") catch unreachable,
        .reduce_only = false,
        .order_type = .{ .limit = .{ .tif = .Gtc } },
        .cloid = types.ZERO_CLOID,
    };

    const batch = types.BatchOrder{
        .orders = &[_]types.OrderRequest{order},
        .grouping = .na,
    };

    const nonce: u64 = @intCast(std.time.milliTimestamp());
    std.debug.print("Placing limit buy: 0.001 BTC @ $1 (GTC)...\n", .{});
    var result = try client.place(signer, batch, nonce, null, null);
    defer result.deinit();

    std.debug.print("Response: {s}\n\n", .{result.body});

    // ── Parse OID ────────────────────────────────────────────────
    var json = try result.json();
    const statuses = ((json.object.get("response") orelse return).object.get("data") orelse return).object.get("statuses") orelse return;

    if (statuses.array.items.len == 0) return;
    const first = statuses.array.items[0];
    const resting = first.object.get("resting") orelse {
        std.debug.print("Order did not rest: {s}\n", .{result.body});
        return;
    };
    const oid = resting.object.get("oid").?.integer;
    std.debug.print("Order resting — OID: {d}\n", .{oid});

    // ── Query ────────────────────────────────────────────────────
    var status = try client.orderStatus(&addr, @intCast(oid));
    defer status.deinit();
    std.debug.print("Order status: {s}\n\n", .{status.body});

    // ── Cancel ───────────────────────────────────────────────────
    const cancel = types.BatchCancel{
        .cancels = &[_]types.Cancel{.{
            .asset = 0,
            .oid = @intCast(oid),
        }},
    };
    const cancel_nonce: u64 = @intCast(std.time.milliTimestamp());
    std.debug.print("Cancelling OID {d}...\n", .{oid});
    var cancel_result = try client.cancel(signer, cancel, cancel_nonce, null, null);
    defer cancel_result.deinit();
    std.debug.print("Cancel response: {s}\n", .{cancel_result.body});
}
