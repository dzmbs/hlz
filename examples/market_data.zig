//! Fetch live market data from Hyperliquid — no key required.
//!
//! Queries perp metadata, the ETH order book, and account state for a public
//! address. All endpoints are unauthenticated info queries.
//!
//! Usage:
//!   zig build example-market_data
//!
//! Output:
//!   BTC          mid=     95234.0  OI=    21876.12
//!   ETH          mid=      2456.5  OI=  583233.30
//!   ...
//!   ETH order book (top 5):
//!     bid_sz      bid_px  |  ask_px      ask_sz
//!   ...

const std = @import("std");
const hlz = @import("hlz");

const Client = hlz.hypercore.client.Client;
const Decimal = hlz.math.decimal.Decimal;

/// Format a Decimal into a stack buffer for printing.
fn fmtDec(d: Decimal) []const u8 {
    const S = struct {
        var bufs: [8][32]u8 = undefined;
        var idx: usize = 0;
    };
    const i = S.idx % 8;
    S.idx +%= 1;
    return d.toString(&S.bufs[i]) catch "?";
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var client = Client.mainnet(allocator);
    defer client.deinit();

    // ── Perp universe ────────────────────────────────────────────
    var meta = try client.getMetaAndAssetCtxs(null);
    defer meta.deinit();

    std.debug.print("Perps ({d} markets):\n", .{meta.entries.len});
    for (meta.entries[0..@min(10, meta.entries.len)]) |entry| {
        const mid = entry.ctx.midPx orelse entry.ctx.markPx orelse continue;
        std.debug.print("  {s: <12} mid={s: >12}  OI={s: >14}\n", .{
            entry.meta.name,
            fmtDec(mid),
            fmtDec(entry.ctx.openInterest),
        });
    }

    // ── L2 order book ────────────────────────────────────────────
    var book = try client.getL2Book("ETH");
    defer book.deinit();

    const bids = book.value.levels[0];
    const asks = book.value.levels[1];
    const depth = @min(5, @min(bids.len, asks.len));

    std.debug.print("\nETH order book (top {d} levels):\n", .{depth});
    std.debug.print("  {s: >12}  {s: >12}  |  {s: <12}  {s: >12}\n", .{ "bid_sz", "bid_px", "ask_px", "ask_sz" });
    for (0..depth) |i| {
        std.debug.print("  {s: >12}  {s: >12}  |  {s: <12}  {s: >12}\n", .{
            fmtDec(bids[i].sz), fmtDec(bids[i].px),
            fmtDec(asks[i].px), fmtDec(asks[i].sz),
        });
    }

    // ── Account state ────────────────────────────────────────────
    const address = "0xc64cc00b46101bd40aa1c3121195e85c0b0918d8";
    var state = try client.getClearinghouseState(address, null);
    defer state.deinit();

    const margin = state.value.marginSummary;
    std.debug.print("\nAccount {s}:\n", .{address});
    std.debug.print("  Account value:  {s}\n", .{fmtDec(margin.accountValue)});
    std.debug.print("  Margin used:    {s}\n", .{fmtDec(margin.totalMarginUsed)});

    for (state.value.assetPositions) |ap| {
        const pos = ap.position;
        if (!pos.szi.isZero()) {
            std.debug.print("  {s: <12} size={s: >12}  pnl={s}\n", .{
                pos.coin,
                fmtDec(pos.szi),
                if (pos.unrealizedPnl) |p| fmtDec(p) else "—",
            });
        }
    }
}
