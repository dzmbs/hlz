---
name: add-cli-command
description: Add a new CLI command to hlz. Use when implementing a new subcommand for the hlz CLI tool.
---

# Add CLI Command

Follow these steps to add a new CLI command to hlz. Touch exactly these files:

## 1. Define the args struct — `src/cli/args.zig`

1. Add a new variant to the `Command` union (alphabetical order).
2. Create a new args struct (e.g., `FooArgs`) with the fields the command needs.
3. Add the command name to `HelpTopic` enum.
4. Add parsing logic in the `parse()` function's command switch.
5. Add help text in the help section.

## 2. Implement the command — `src/cli/commands.zig`

1. Add a public function: `pub fn foo(allocator: Allocator, w: *Writer, config: Config, a: args_mod.FooArgs) CmdError!void`
2. Follow the existing pattern:
   - Create a client with `makeClient(allocator, config)`
   - Make the API call
   - Branch on `w.format` for `.json` vs `.pretty` output
   - For read commands: normalize output (resolve indices, compute derived fields)
   - For write commands: pass through raw API response

## 3. Wire it up — `src/cli/main.zig`

1. Add a case in the main `switch (cmd)` that calls your command function.
2. Follow the error handling pattern: `catch |e| return exit(&w, "foo", e)`

## 4. Add SDK support if needed — `src/sdk/client.zig`

If the command needs a new API endpoint:

1. Add the request method to `Client`
2. Add response types in `src/sdk/response.zig`
3. For exchange actions (writes), add signing support in `src/sdk/signing.zig` and types in `src/sdk/types.zig`

## Checklist

- [ ] Args struct defined in `args.zig`
- [ ] `Command` union updated
- [ ] `HelpTopic` updated
- [ ] Parse logic added
- [ ] Help text added
- [ ] Command function in `commands.zig`
- [ ] Wired in `main.zig` switch
- [ ] SDK endpoint added (if new API call)
- [ ] `zig build test` passes
- [ ] `zig build hlz` builds successfully
- [ ] Output works in both JSON and pretty modes

## Conventions

- Read commands normalize data for UX; write commands pass through raw API responses
- All commands support `--json` output (auto when piped)
- Use `w.table()` for tabular output, `w.json()` for JSON
- Follow existing patterns — look at a similar command for reference
- No interactive prompts ever
