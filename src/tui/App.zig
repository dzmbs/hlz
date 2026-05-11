//! TUI Application framework — event loop with tick-based rendering.
//!
//! Handles:
//!   - Terminal init/deinit (raw mode, alternate screen)
//!   - Double-buffered rendering (only flush changed cells)
//!   - Key polling (non-blocking)
//!   - Resize detection
//!   - Fixed tick rate
//!
//! Usage:
//!   var app = try App.init(allocator, io);
//!   defer app.deinit();
//!   while (app.running) {
//!       app.beginFrame();
//!       // ... render widgets to app.buf ...
//!       app.endFrame();
//!       if (app.pollKey()) |key| { ... }
//!   }

const std = @import("std");
const Terminal = @import("Terminal.zig");
const Buffer = @import("Buffer.zig");

pub const Rect = Buffer.Rect;
pub const Style = Buffer.Style;

const App = @This();

term: Terminal,
buf: Buffer,
prev: Buffer,
allocator: std.mem.Allocator,
running: bool = true,
tick_ns: u64 = 200_000_000, // 200ms = 5 FPS default
frame: u64 = 0,

pub fn init(allocator: std.mem.Allocator, io: std.Io) !App {
    const term = try Terminal.init(io);
    Terminal.clear(io);
    const w = term.width;
    const h = term.height;
    const buf = try Buffer.init(allocator, w, h);
    const prev = try Buffer.init(allocator, w, h);
    return .{
        .term = term,
        .buf = buf,
        .prev = prev,
        .allocator = allocator,
    };
}

pub fn deinit(self: *App) void {
    self.term.deinit();
    self.buf.deinit();
    self.prev.deinit();
}

/// Set tick rate in milliseconds.
pub fn setTickMs(self: *App, ms: u64) void {
    self.tick_ns = ms * 1_000_000;
}

/// Begin a new frame: check resize, clear buffer.
pub fn beginFrame(self: *App) void {
    // Detect resize
    const old_w = self.term.width;
    const old_h = self.term.height;
    self.term.refreshSize();
    if (self.term.width != old_w or self.term.height != old_h) {
        self.buf.resize(self.term.width, self.term.height) catch return;
        self.prev.resize(self.term.width, self.term.height) catch return;
        self.prev.clear();
        Terminal.clear(self.term.io);
    }
    self.buf.clear();
}

/// End frame: diff-flush and swap buffers.
pub fn endFrame(self: *App) void {
    self.buf.flush(&self.prev, self.term.io);
    @memcpy(self.prev.cells, self.buf.cells);
    self.frame += 1;
}

/// Sleep for the tick interval.
pub fn tick(self: *App) void {
    std.Io.sleep(
        self.term.io,
        std.Io.Duration.fromNanoseconds(@intCast(self.tick_ns)),
        .awake,
    ) catch {};
}

/// Poll for a key (non-blocking).
pub fn pollKey(_: *App) ?Terminal.Key {
    return Terminal.pollKey();
}

/// Get terminal width.
pub fn width(self: *const App) u16 {
    return self.term.width;
}

/// Get terminal height.
pub fn height(self: *const App) u16 {
    return self.term.height;
}

/// Convenience: full-screen rect.
pub fn fullRect(self: *const App) Buffer.Rect {
    return .{ .x = 0, .y = 0, .w = self.term.width, .h = self.term.height };
}
