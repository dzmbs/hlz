#!/usr/bin/env python3
"""Generate EIP-712 test vectors for all Hyperliquid typed data signing.

Uses eth_account for signing — same library as the official Python SDK.
Output: JSON with struct hashes, signing hashes, and signatures for a known key.

Usage:
    pip install eth-account
    python generate_eip712_vectors.py > eip712_vectors.json
"""

import json
from eth_account import Account
from eth_account.messages import encode_typed_data
from eth_utils import keccak

# Same test key used in our Zig test suite
PRIVATE_KEY = "0xe908f86dbb4d55ac876378565aafeabc187f6690f046459397b17d9b9a19688e"
wallet = Account.from_key(PRIVATE_KEY)

EIP712_DOMAIN_TYPES = [
    {"name": "name", "type": "string"},
    {"name": "version", "type": "string"},
    {"name": "chainId", "type": "uint256"},
    {"name": "verifyingContract", "type": "address"},
]

MAINNET_DOMAIN = {
    "name": "HyperliquidSignTransaction",
    "version": "1",
    "chainId": 42161,
    "verifyingContract": "0x0000000000000000000000000000000000000000",
}

TESTNET_DOMAIN = {
    "name": "HyperliquidSignTransaction",
    "version": "1",
    "chainId": 421614,
    "verifyingContract": "0x0000000000000000000000000000000000000000",
}

def sign_typed(primary_type, types, message, domain=MAINNET_DOMAIN):
    data = {
        "domain": domain,
        "types": {
            primary_type: types,
            "EIP712Domain": EIP712_DOMAIN_TYPES,
        },
        "primaryType": primary_type,
        "message": message,
    }
    structured = encode_typed_data(full_message=data)
    signed = wallet.sign_message(structured)
    return {
        "r": hex(signed.r),
        "s": hex(signed.s),
        "v": signed.v,
        "signature": signed.signature.hex(),
    }

vectors = {"signer_address": wallet.address, "private_key": PRIVATE_KEY, "vectors": []}

# UsdSend
msg = {"hyperliquidChain": "Mainnet", "destination": "0x0000000000000000000000000000000000000001", "amount": "100.0", "time": 1700000000000}
types = [{"name": "hyperliquidChain", "type": "string"}, {"name": "destination", "type": "string"}, {"name": "amount", "type": "string"}, {"name": "time", "type": "uint64"}]
sig = sign_typed("HyperliquidTransaction:UsdSend", types, msg)
vectors["vectors"].append({"name": "UsdSend", "message": msg, "signature": sig})

# Withdraw (same types as UsdSend)
msg = {"hyperliquidChain": "Mainnet", "destination": "0x0000000000000000000000000000000000000001", "amount": "50.0", "time": 1700000000000}
types = [{"name": "hyperliquidChain", "type": "string"}, {"name": "destination", "type": "string"}, {"name": "amount", "type": "string"}, {"name": "time", "type": "uint64"}]
sig = sign_typed("HyperliquidTransaction:Withdraw", types, msg)
vectors["vectors"].append({"name": "Withdraw", "message": msg, "signature": sig})

# UsdClassTransfer
msg = {"hyperliquidChain": "Mainnet", "amount": "1000.0", "toPerp": True, "nonce": 1700000000000}
types = [{"name": "hyperliquidChain", "type": "string"}, {"name": "amount", "type": "string"}, {"name": "toPerp", "type": "bool"}, {"name": "nonce", "type": "uint64"}]
sig = sign_typed("HyperliquidTransaction:UsdClassTransfer", types, msg)
vectors["vectors"].append({"name": "UsdClassTransfer", "message": msg, "signature": sig})

# TokenDelegate
msg = {"hyperliquidChain": "Mainnet", "validator": "0x0000000000000000000000000000000000000002", "wei": 1000000000000000000, "isUndelegate": False, "nonce": 1700000000000}
types = [{"name": "hyperliquidChain", "type": "string"}, {"name": "validator", "type": "address"}, {"name": "wei", "type": "uint64"}, {"name": "isUndelegate", "type": "bool"}, {"name": "nonce", "type": "uint64"}]
sig = sign_typed("HyperliquidTransaction:TokenDelegate", types, msg)
vectors["vectors"].append({"name": "TokenDelegate", "message": msg, "signature": sig})

# ApproveBuilderFee
msg = {"hyperliquidChain": "Mainnet", "maxFeeRate": "0.001", "builder": "0x0000000000000000000000000000000000000003", "nonce": 1700000000000}
types = [{"name": "hyperliquidChain", "type": "string"}, {"name": "maxFeeRate", "type": "string"}, {"name": "builder", "type": "address"}, {"name": "nonce", "type": "uint64"}]
sig = sign_typed("HyperliquidTransaction:ApproveBuilderFee", types, msg)
vectors["vectors"].append({"name": "ApproveBuilderFee", "message": msg, "signature": sig})

# ApproveAgent
msg = {"hyperliquidChain": "Mainnet", "agentAddress": "0x0000000000000000000000000000000000000004", "agentName": "test-agent", "nonce": 1700000000000}
types = [{"name": "hyperliquidChain", "type": "string"}, {"name": "agentAddress", "type": "address"}, {"name": "agentName", "type": "string"}, {"name": "nonce", "type": "uint64"}]
sig = sign_typed("HyperliquidTransaction:ApproveAgent", types, msg)
vectors["vectors"].append({"name": "ApproveAgent", "message": msg, "signature": sig})

# SpotSend
msg = {"hyperliquidChain": "Mainnet", "destination": "0x0000000000000000000000000000000000000001", "token": "PURR", "amount": "100.0", "time": 1700000000000}
types = [{"name": "hyperliquidChain", "type": "string"}, {"name": "destination", "type": "string"}, {"name": "token", "type": "string"}, {"name": "amount", "type": "string"}, {"name": "time", "type": "uint64"}]
sig = sign_typed("HyperliquidTransaction:SpotSend", types, msg)
vectors["vectors"].append({"name": "SpotSend", "message": msg, "signature": sig})

# UserDexAbstraction
msg = {"hyperliquidChain": "Mainnet", "user": "0x0000000000000000000000000000000000000005", "enabled": True, "nonce": 1700000000000}
types = [{"name": "hyperliquidChain", "type": "string"}, {"name": "user", "type": "address"}, {"name": "enabled", "type": "bool"}, {"name": "nonce", "type": "uint64"}]
sig = sign_typed("HyperliquidTransaction:UserDexAbstraction", types, msg)
vectors["vectors"].append({"name": "UserDexAbstraction", "message": msg, "signature": sig})

# UserSetAbstraction
msg = {"hyperliquidChain": "Mainnet", "user": "0x0000000000000000000000000000000000000005", "abstraction": "test-abstraction", "nonce": 1700000000000}
types = [{"name": "hyperliquidChain", "type": "string"}, {"name": "user", "type": "address"}, {"name": "abstraction", "type": "string"}, {"name": "nonce", "type": "uint64"}]
sig = sign_typed("HyperliquidTransaction:UserSetAbstraction", types, msg)
vectors["vectors"].append({"name": "UserSetAbstraction", "message": msg, "signature": sig})

print(json.dumps(vectors, indent=2))
