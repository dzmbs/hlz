# WebSocket

Real-time market data and user event streaming via WebSocket.

## Subscription Types

| Type | Data | Auth |
|------|------|------|
| `trades` | Real-time trades | No |
| `l2Book` | Order book updates (set `fast: true` for the 5-level low-latency feed) | No |
| `bbo` | Best bid/offer | No |
| `candle` | Candlestick updates | No |
| `allMids` | All mid prices | No |
| `activeAssetCtx` | Asset context (funding, OI); accepts `fast: true` | No |
| `fastAssetCtxs` | Low-latency mark/mid for every asset | No |
| `userEvents` | User fills, liquidations | Yes |
| `userFills` | User trade fills | Yes |
| `userFundings` | User funding payments | Yes |
| `orderUpdates` | Order status changes | Yes |
| `notification` | System notifications | Yes |
| `webData2` | Extended web data | Yes |
| `activeAssetData` | User asset data (leverage, margin) | Yes |
| `clearinghouseState` | User margin/positions on a single dex | Yes |
| `allDexsClearinghouseState` | User margin/positions across every dex | Yes |
| `openOrders` | User open orders on a single dex | Yes |
| `spotState` | User spot balances + holds | Yes |

## Protocol Details

### Connection

```
wss://api.hyperliquid.xyz/ws     (mainnet)
wss://api.hyperliquid-testnet.xyz/ws  (testnet)
```

### Ping/Pong

Hyperliquid uses **app-level** ping/pong (not WebSocket protocol-level):

- Server sends: `Ping` (plain text)
- Client must respond: `{"method":"pong"}`
- Timeout: ~30 seconds without pong → disconnect

### Subscribe

```json
{"method":"subscribe","subscription":{"type":"trades","coin":"BTC"}}
{"method":"subscribe","subscription":{"type":"l2Book","coin":"BTC","fast":true}}
{"method":"subscribe","subscription":{"type":"spotState","user":"0x..."}}
```

### Unsubscribe

```json
{"method":"unsubscribe","subscription":{"type":"trades","coin":"BTC"}}
```

### Message Format

All messages arrive as JSON with a channel wrapper:

```json
{"channel":"trades","data":[{"coin":"BTC","side":"B","px":"97432.5","sz":"0.1","time":1234567890}]}
```

The SDK's `ws_types.extractData()` strips the outer wrapper — decode functions receive the `data` value directly.

## SDK Usage

```zig
const Ws = hlz.hypercore.ws;

// The WS module provides subscription type definitions
// Actual WebSocket connection is managed by the terminal/CLI layer
// using websocket.zig for the transport
```

## Thread Safety

- WebSocket reads are **blocking** — run in a dedicated thread
- Use `shutdown(fd)` to break out of a blocking read (for coin/interval switches)
- **Do not** use `SO_RCVTIMEO` with TLS on macOS (causes segfaults)
- Parse messages outside the lock, apply results under the lock
