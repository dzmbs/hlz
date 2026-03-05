//! Subscribe to real-time market data via WebSocket.
//!
//! Connects to Hyperliquid mainnet and subscribes to BTC + ETH trades and
//! the ETH L2 order book. Prints messages as they arrive.
//!
//! Usage:
//!   zig build example-websocket
//!
//! Output:
//!   [trades] {"coin":"BTC","side":"B","px":"95234.0","sz":"0.01",...}
//!   [l2Book] {"coin":"ETH","levels":[[{"px":"2456.5","sz":"12.3",...}],...]}
//!   ...
//!
//! Available subscriptions:
//!   .trades      — real-time trades for a coin
//!   .l2Book      — order book snapshots
//!   .bbo         — best bid/offer
//!   .candle      — candlestick updates
//!   .allMids     — all mid prices
//!   .orderUpdates, .userFills, .userEvents — user-specific (needs address)

const std = @import("std");
const hlz = @import("hlz");

const ws = hlz.hypercore.ws;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var conn = try ws.Connection.connect(allocator, .mainnet);
    defer conn.close();

    try conn.subscribe(.{ .trades = .{ .coin = "BTC" } });
    try conn.subscribe(.{ .trades = .{ .coin = "ETH" } });
    try conn.subscribe(.{ .l2Book = .{ .coin = "ETH" } });

    std.debug.print("Listening (Ctrl+C to stop)...\n\n", .{});

    conn.setReadTimeout(10_000);

    var count: usize = 0;
    while (count < 100) : (count += 1) {
        switch (try conn.next()) {
            .message => |m| {
                const max = 200;
                const truncated = m.raw_json.len > max;
                std.debug.print("[{s}] {s}{s}\n", .{
                    @tagName(m.channel),
                    if (truncated) m.raw_json[0..max] else m.raw_json,
                    if (truncated) "..." else "",
                });
            },
            .timeout => std.debug.print("(keepalive)\n", .{}),
            .closed => {
                std.debug.print("Connection closed.\n", .{});
                break;
            },
        }
    }
}
