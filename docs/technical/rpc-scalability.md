# RPC Scalability

AgentCoin's RPC model mirrors Bitcoin: **each miner is responsible for their own infrastructure.** The protocol itself has zero recurring costs after deployment.

---

## Default: Alchemy x402 (v0.6.0+)

As of v0.6.0, the CLI uses [Alchemy x402](https://x402.alchemy.com/) by default -- a premium Base RPC endpoint that charges per-request via the [x402 payment protocol](https://www.x402.org/). Your mining wallet pays automatically with USDC on Base.

**No API key, no account, no rate limits.** Just fund your wallet with USDC (the `apow fund` command handles this automatically via auto-split).

- **Cost:** ~$0.00002 per RPC call (~2 USDC covers ~100K calls)
- **Fallback:** If no USDC is available, the CLI automatically falls back to the public RPC
- **Override:** Set `RPC_URL` in `.env` to use a custom endpoint (disables x402)

---

## The Bitcoin Parallel

Bitcoin miners pay for:
- Mining hardware (ASICs)
- Electricity
- Internet connection
- Full node (or pool access)

**The Bitcoin protocol has zero infrastructure costs.** It runs forever with zero maintenance.

AgentCoin works identically. Each miner provides:
- Their own RPC endpoint (x402 default, free, paid, or self-hosted)
- Their own LLM API key (for SMHL solving during minting only)
- Their own wallet + private key
- Their own compute (CPU for PoW grinding)

**Protocol recurring costs: $0 forever.** Contracts are on-chain, immutable, ownerless.

---

## How Miners Configure RPC

Each miner sets their RPC in `.env`:

```bash
# Default: Alchemy x402 (no RPC_URL needed — just have USDC in wallet)
# The CLI auto-detects and uses x402 when RPC_URL is not set.

# Custom Alchemy key (free tier: 300M CU/month)
RPC_URL=https://base-mainnet.g.alchemy.com/v2/THEIR_KEY

# Free public RPC (unreliable for sustained mining)
RPC_URL=https://mainnet.base.org

# Their own Base node
RPC_URL=http://localhost:8545
```

The default (x402) requires USDC in your mining wallet. The `apow fund` command auto-splits deposits into ETH (gas) + USDC (RPC). If no USDC is available, the CLI falls back to the public Base RPC (`mainnet.base.org`), which has rate limits.

---

## Cost Per Miner

| Setup | Monthly Cost | Use Case |
|-------|-------------|----------|
| Alchemy x402 (default) | ~$2/mo | **Recommended.** Premium RPC, pay-per-request via USDC |
| Custom Alchemy (free tier) | $0 | 300M CU/month, reliable |
| Alchemy PAYG | ~$20/mo | Power mining |
| Public Base RPC | $0 | **Not recommended.** Unreliable, frequent 429 errors |
| Own Base node | Electricity only | Mining farm |

**At 10,000 concurrent miners:** Protocol cost = $0. Each miner's cost = $0-20/mo (their choice).

---

## MEV & Sniper Resistance

AgentCoin is sniper-resistant by design. No additional protection mechanisms needed.

### Base L2 Natural Resistance

- **No public mempool:** Coinbase's centralized sequencer processes FIFO
- **No gas auctions:** uniform base fee (~0.001 gwei), no priority bidding
- **2-second blocks:** minimal extraction window

### Protocol-Level Protection

| Mechanism | How It Helps |
|-----------|-------------|
| Transfer lock | Zero AGENT on DEXes pre-LP. No pre-positioning possible |
| No team/VC allocation | Only miners hold tokens, earned through real work |
| Atomic LP deployment | `deployLP()` creates pool + mints position in one tx |
| Eternal UNCX lock | Deployer can't rugpull. Removes #1 reason bots snipe |

### Why NOT to Add Extra Mechanisms

| Mechanism | Problem |
|-----------|---------|
| Max tx size (first N blocks) | Punishes legitimate large miners |
| Sell cooldown | Unfair to miners who earned tokens |
| Anti-snipe tax | Looks scammy, breaks DeFi composability |
| Whitelist trading period | Defeats permissionless ethos |

**Fair launch = no artificial restrictions.** Everyone mines at equal difficulty, earns equal rewards, trades freely.
