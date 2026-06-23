# Transfers

Send tokens between addresses and between balance contexts (perp ↔ spot).

## `hlz send <AMOUNT> [TOKEN] <DESTINATION>`

### Send to Another Address

```bash
# Send USDC (default token)
hlz send 100 0xRecipientAddress

# Send a specific token
hlz send 5 HYPE 0xRecipientAddress

# Send spot token
hlz send 10 PURR/USDC 0xRecipientAddress
```

### Internal Transfers

Move funds between your own perp and spot balances:

```bash
# Perp → Spot
hlz send 100 USDC --to spot

# Spot → Perp
hlz send 100 USDC --to perp
```

Transfers on Hyperliquid are **free and instant** — no gas fees.

### Agent-Signed Transfers (`--agent`)

Pass `--agent` to route the transfer through `agentSendAsset` — the L1-action
variant signed by an API wallet rather than EIP-712. The destination MUST equal
the signer's address, so this is limited to self-transfers across DEXes, the
spot balance, or between sub-accounts of the same master account.

```bash
hlz send 100 USDC --from perp --to spot --agent
```

Useful when an agent wallet needs to move funds across balance contexts without
the master account ever being online to typed-data sign.
