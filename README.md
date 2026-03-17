# APoW — Agentic Proof of Work

Mineable ERC-20 on Base. Three contracts, one mining client.

## Architecture

```
MiningAgent (ERC-721)     AgentCoin (ERC-20)        LPVault
    NFT mining rigs    ──>   $AGENT token mining   <──  LP accumulation
    100k supply              21M supply                 Uniswap V3 + UNCX
```

**MiningAgent** — ERC-721 NFTs that act as mining rigs. Each has a rarity tier and hashpower multiplier. Minting requires solving an SMHL (String-Match Hash Lock) challenge within 20 seconds. Mint fees flow to LPVault.

**AgentCoin** — ERC-20 token mined via dual proof: SMHL challenge + SHA-3 proof-of-work hash below a dynamic difficulty target. Miners must own a MiningAgent NFT. One mine per Base block. Difficulty adjusts every 64 mines targeting 1 mine per 5 blocks (~10s).

**LPVault** — Accumulates ETH from NFT mint fees. When threshold is reached (4.93 ETH), deploys a full-range AGENT/USDC Uniswap V3 position locked permanently via UNCX. Deployer retains fee collection rights.

## Tokenomics

| Parameter | Value |
|-----------|-------|
| Max supply | 21,000,000 AGENT |
| LP reserve | 2,100,000 AGENT (10%) |
| Mineable supply | 18,900,000 AGENT (90%) |
| Base reward | 3 AGENT per mine |
| Era interval | 500,000 mines |
| Reward decay | -10% per era |
| Difficulty adjustment | Every 64 mines |
| Target block interval | 5 Base blocks (~10s) |

## NFT Rarity

| Tier | Probability | Hashpower | Reward Multiplier |
|------|------------|-----------|-------------------|
| Common | 60% | 100 | 1.0x |
| Uncommon | 25% | 150 | 1.5x |
| Rare | 10% | 200 | 2.0x |
| Epic | 4% | 300 | 3.0x |
| Mythic | 1% | 500 | 5.0x |

NFTs have fully on-chain generative pixel art (MinerArt.sol). Metadata updates dynamically as the NFT mines — mine count and earnings are reflected in the token URI.

## NFT Mint Pricing

Exponential decay: starts at 0.00217 ETH (~$5), drops 10% every 1,000 mints, floored at 0.00005 ETH (~$0.12). 100,000 max supply.

## Security

- **Eternal LP lock** — UNCX `ETERNAL_LOCK` (`type(uint256).max`). Liquidity can never be withdrawn. Fee collection still works via `collectAddress`.
- **Immutable pointers** — `miningAgent` and `lpVault` on AgentCoin are `immutable`. MiningAgent setters are one-time only.
- **Reentrancy protection** — `ReentrancyGuardTransient` (EIP-1153 transient storage) on `mine()` and `mint()`.
- **LP mint slippage** — 90% minimum on Uniswap V3 position mint amounts.
- **Bot deterrent** — SMHL challenges require LLM-grade string manipulation. PoW hash includes `msg.sender`, preventing nonce transfer. `tx.origin` check blocks contract callers.
- **One mine per block** — `block.number > lastMineBlockNumber` enforced on-chain.
- **Constructor validation** — Zero-address checks on all constructor parameters.
- **Events** — `Mined`, `DifficultyAdjusted`, `MinerMinted`, `LPDeployed`, `AgentCoinSet`, `LPVaultSet` for full on-chain observability.

## Post-Deploy

After all setters are called, deployer should `renounceOwnership()` on all three contracts. This makes the system fully immutable — no admin can change any pointers.

## Project Structure

```
contracts/
  src/
    AgentCoin.sol          ERC-20 + PoAW mining
    MiningAgent.sol        ERC-721 mining rig NFTs
    LPVault.sol            LP accumulation + Uniswap V3 + UNCX lock
    interfaces/            IAgentCoin, IMiningAgent
    lib/MinerArt.sol       On-chain generative pixel art
  test/                    169 tests (unit, edge, integration, simulation, fork)
  script/                  Foundry deploy scripts
miner/
  src/                     TypeScript mining client
```

## Development

```bash
# Install dependencies
cd contracts && forge install

# Run tests (169 tests)
forge test

# Run fork tests against Base mainnet
forge test --match-path test/LPVaultFork.t.sol --fork-url $BASE_RPC

# Inspect storage layout
forge inspect AgentCoin storage-layout
```

## Deploy Order

1. Deploy `MiningAgent`
2. Deploy `LPVault(deployer)`
3. Deploy `AgentCoin(miningAgent, lpVault)` — mints 2.1M AGENT to LPVault
4. `miningAgent.setLPVault(lpVault)`
5. `miningAgent.setAgentCoin(agentCoin)`
6. `lpVault.setAgentCoin(agentCoin)`
7. Renounce ownership on all three contracts

## Chain

Base (Coinbase L2). Solidity 0.8.26, Cancun EVM, compiled with `via_ir` + 200 optimizer runs.

## License

MIT
