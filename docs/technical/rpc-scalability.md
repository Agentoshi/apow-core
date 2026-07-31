# RPC Scalability

AgentCoin's RPC model mirrors Bitcoin: **each miner is responsible for their own infrastructure.** The protocol itself has zero recurring costs after deployment.

---

## RPC Options (v0.8.0+)

As of v0.8.0, you must configure an RPC endpoint. Two options:

### Option A: Bring Your Own RPC (Recommended)

Set `RPC_URL` in `.env` with a free or paid Base RPC URL from [Alchemy](https://www.alchemy.com/) (free, 300M CU/month), [QuickNode](https://www.quicknode.com/), Infura, or any provider.

### Option B: QuickNode x402 (Zero Setup)

Set `USE_X402=true` in `.env`. Your mining wallet pays for RPC usage via the [x402 payment protocol](https://www.x402.org/). No API key, no account, and no rate-limit setup.

- **Starting balance:** 2.00 USDC minimum on Base, with more recommended for headroom
- **Billing model:** wallet-paid, usage-based RPC
- **No API key needed:** Payment is automatic via your wallet's USDC

---

## The Bitcoin Parallel

Bitcoin miners pay for:
- Mining hardware (ASICs)
- Electricity
- Internet connection
- Full node (or pool access)

**The Bitcoin protocol has zero infrastructure costs.** It runs forever with zero maintenance.

AgentCoin works identically. Each miner provides:
- Their own RPC endpoint (free, paid, x402, or self-hosted)
- Their own LLM access (ClawRouter, API key, or local model for minting only)
- Their own wallet + private key
- Their own compute (CPU for PoW grinding)

Mining RPC costs are borne by each miner rather than a protocol-operated RPC service. The contracts are on-chain and non-upgradeable; owner authority remains during the required LP lifecycle.

---

## How Miners Configure RPC

Each miner sets their RPC in `.env`:

```bash
# Option A: Custom RPC URL (free from Alchemy, QuickNode, etc.)
# RPC_URL=https://base-mainnet.g.alchemy.com/v2/YOUR_KEY

# Option B: QuickNode x402 (wallet-paid auto-pay)
# USE_X402=true

# Custom Alchemy key (free tier: 300M CU/month)
RPC_URL=https://base-mainnet.g.alchemy.com/v2/THEIR_KEY

# Free public RPC (unreliable for sustained mining)
RPC_URL=https://mainnet.base.org

# Their own Base node
RPC_URL=http://localhost:8545
```

If using x402, you need USDC in your mining wallet. Start with at least 2.00 USDC and add more for headroom. The `apow fund` command auto-splits deposits into ETH (gas) + USDC (RPC).

---

## Cost Per Miner

| Setup | Monthly Cost | Use Case |
|-------|-------------|----------|
| Custom Alchemy (free tier) | $0 | **Recommended.** 300M CU/month, reliable |
| QuickNode x402 (zero setup) | Usage-based | Premium wallet-paid RPC via USDC, no API key needed |
| Alchemy PAYG | ~$20/mo | Power mining |
| Public Base RPC | $0 | **Not recommended.** Unreliable, frequent 429 errors |
| Own Base node | Electricity only | Mining farm |

**At 10,000 concurrent miners:** Protocol cost = $0. Each miner's cost = $0-20/mo (their choice).

---
