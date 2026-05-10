const std = @import("std");
const builtin = @import("builtin");

var installed_io: ?std.Io = null;
var installed_environ_map: ?*const std.process.Environ.Map = null;

pub fn installIo(app_io: std.Io) void {
    installed_io = app_io;
}

pub fn installEnvironMap(environ_map: *const std.process.Environ.Map) void {
    installed_environ_map = environ_map;
}

pub fn io() std.Io {
    if (installed_io) |app_io| return app_io;
    if (builtin.is_test) return std.testing.io;
    return std.Io.Threaded.global_single_threaded.io();
}

pub fn getenv(name: []const u8) ?[]const u8 {
    if (installed_environ_map) |environ_map| {
        const value = environ_map.get(name) orelse return null;
        return if (value.len == 0) null else value;
    }

    var name_buf: [64]u8 = undefined;
    const name_z = std.fmt.bufPrintZ(&name_buf, "{s}", .{name}) catch return null;
    const value = std.c.getenv(name_z.ptr) orelse return null;
    const slice = std.mem.span(value);
    return if (slice.len == 0) null else slice;
}

/// Hyperliquid nonces are wall-clock epoch milliseconds.
pub fn nonceMs() u64 {
    return @intCast(std.Io.Clock.real.now(io()).toMilliseconds());
}

pub fn wallMs() i64 {
    return std.Io.Clock.real.now(io()).toMilliseconds();
}

pub fn sleepNs(ns: u64) std.Io.Cancelable!void {
    return std.Io.sleep(io(), std.Io.Duration.fromNanoseconds(@intCast(ns)), .awake);
}

pub fn fillRandomSecure(buffer: []u8) std.Io.RandomSecureError!void {
    return std.Io.randomSecure(io(), buffer);
}
