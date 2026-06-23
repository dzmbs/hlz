# Trading

All trading commands require authentication. See [Configuration](/introduction/configuration).

## Placing Orders

### `hlz buy <COIN> <SIZE> [@PRICE]`

```bash
# Market buy (executes immediately at best available price)
hlz buy BTC 0.1

# Limit buy at $50,000
hlz buy BTC 0.1 @50000

# With take-profit and stop-loss
hlz buy BTC 0.1 @50000 --tp 55000 --sl 48000

# Reduce-only order
hlz sell BTC 0.1 --reduce-only

# Maker-only (post-only)
hlz buy ETH 1.0 @3500 --tif alo
```

### Spot Orders

Use `BASE/QUOTE` syntax for spot markets:

```bash
hlz buy PURR/USDC 100 @0.065     # Limit buy 100 PURR
hlz sell HYPE/USDC 1.0            # Market sell HYPE
hlz buy HPL/USDH 0.5 @500        # Buy on non-USDC pair
```

Spot pairs are resolved via the spot universe. Transfer USDC to spot balance first with `hlz send <AMT> USDC --to spot`.

### `hlz sell <COIN> <SIZE> [@PRICE]`

Same syntax as `buy`, but sells.

```bash
hlz sell ETH 1.0 @3500     # Limit sell
hlz sell SOL 10             # Market sell
```

### Trigger Orders

```bash
# Take-profit trigger at $55,000
hlz sell BTC 0.1 --trigger-above 55000

# Stop-loss trigger at $48,000
hlz sell BTC 0.1 --trigger-below 48000
```

### Dry Run

Preview any order without submitting:

```bash
hlz buy BTC 0.1 @50000 --dry-run
# Shows the signed order payload without sending
```

## Managing Orders

### `hlz cancel <COIN> [OID]`

```bash
hlz cancel BTC 12345        # Cancel specific order
hlz cancel BTC              # Cancel all BTC orders
hlz cancel --all            # Cancel all open orders
```

### `hlz modify <COIN> <OID> <SIZE> <PRICE>`

```bash
hlz modify BTC 12345 0.2 51000    # Change size and price
```

## Leverage

### `hlz leverage <COIN> [N]`

```bash
hlz leverage BTC             # Query current leverage
hlz leverage BTC 10          # Set to 10x
```

## Advanced

### `hlz twap <COIN> buy|sell <SIZE> --duration <TIME> --slices <N>`

Time-weighted average price execution. Splits a large order into smaller slices.

```bash
hlz twap BTC buy 1.0 --duration 1h --slices 10
# Places 0.1 BTC buy every 6 minutes for 1 hour
```

### `hlz batch "order1" "order2" ...`

Execute multiple orders atomically.

```bash
hlz batch "buy BTC 0.1 @98000" "sell ETH 1.0 @3500"

# From stdin (useful for scripts)
echo "buy BTC 0.1 @98000
sell ETH 1.0 @3500" | hlz batch --stdin
```

## Trading Flags

| Flag | Description |
|------|-------------|
| `--reduce-only` | Only reduce existing position |
| `--tp <PX>` | Take-profit price (bracket order) |
| `--sl <PX>` | Stop-loss price (bracket order) |
| `--trigger-above <PX>` | Trigger order above price (take-profit) |
| `--trigger-below <PX>` | Trigger order below price (stop-loss) |
| `--slippage <PX>` | Max slippage for market orders |
| `--tif gtc\|ioc\|alo` | Time-in-force (default: gtc) |
| `--builder <ADDR>` | Builder address routing the order |
| `--builder-fee <PCT\|TENTHS_BPS>` | Builder fee (`"0.001%"` or raw tenths-of-bps) |
| `--dry-run`, `-n` | Preview without sending |

## Builder Code

Builder-routed orders carry a per-order fee paid to the builder address. The fee
must be pre-approved via `hlz approve-builder <ADDR> <MAX_FEE_RATE>` once per
builder, then attached to each subsequent order:

```bash
hlz approve-builder 0xBuilder... "0.001%"
hlz buy BTC 0.1 @95000 --builder 0xBuilder... --builder-fee 0.001%
```

Fees pass through as `tenths-of-bps` (1 = 0.0001%) on the wire — the CLI
accepts a percent string (`"0.001%"`) or a raw integer.

## Trigger Order Statuses

When the exchange accepts a trigger order without immediately filling it, the
response status is one of:

| Status | Meaning |
|--------|---------|
| `waiting for trigger` | Trigger order accepted; waiting for its trigger price |
| `waiting to fill` | Order accepted; waiting to fill |
| `resting` | Order on the book (immediate accept of a non-trigger limit) |
| `filled` | Filled immediately (market or aggressive limit) |
| `rejected: <msg>` | Rejected by the exchange |

## Time-in-Force

| Value | Meaning |
|-------|---------|
| `gtc` | Good-til-cancelled (default) |
| `ioc` | Immediate-or-cancel |
| `alo` | Add-liquidity-only (post-only, maker) |
