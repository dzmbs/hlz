# App

`App.zig` manages the frame lifecycle — the entry point for any TUI application.

## Usage

```zig
const std = @import("std");
const tui = @import("tui");

pub fn main(init: std.process.Init) !void {
    var app = try tui.App.init(init.gpa, init.io);
    defer app.deinit(); // restores terminal to cooked mode

    while (true) {
        app.beginFrame();

        // ... render to app.buf ...

        if (app.pollKey()) |key| {
            switch (key) {
                .char => |c| if (c == 'q') break,
                else => {},
            }
        }

        app.endFrame(); // flushes buffer diff to terminal
    }
}
```

## API

### `App.init(allocator, io) -> !App`

Initializes the terminal in raw mode and allocates the double buffer. Pass the process `io` from `std.process.Init`.

### `app.deinit()`

Restores terminal to cooked mode. Always call this (use `defer`).

### `app.beginFrame()`

Starts a new frame. Clears dirty state from previous frame.

### `app.endFrame()`

Flushes the buffer diff to the terminal. Only changed cells are written.

### `app.pollKey() -> ?Key`

Non-blocking key read. Returns `null` if no key is pressed.

Uses `VTIME=0 VMIN=0` for truly non-blocking reads — no blocking, no busy-wait.

### `app.width()` / `app.height()` / `app.fullRect()`

Helpers for current terminal dimensions and the full-screen drawing region.

### `app.buf`

The current frame buffer. Write to this during your render phase.
