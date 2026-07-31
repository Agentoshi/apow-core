# Architecture

**Architecture release:** v0.12.0

AgentCoin is a three-contract system deployed on Base. Each contract has a single responsibility. The contracts are not upgradeable; owner authority is retained temporarily for the LP lifecycle and can be renounced only after all required liquidity operations are complete.

---

## System Overview

```
MiningAgent (ERC-721)              AgentCoin (ERC-20)             LPVault
Agent-gated mining rigs      ──>   $AGENT token mining      <──   LP accumulation
10k supply                          21M supply                     Uniswap V3 + UNCX
```

---

## Contracts

### MiningAgent

The NFT contract. Every mining rig is an ERC-721 mining NFT with capabilities like identity URIs, key-value metadata, and cryptographically verified wallet bindings.

Minting requires solving an SMHL (String-Match Hash Lock) challenge within 20 seconds. All mint fees flow directly to LPVault.

**Key properties:**
- 10,000 max supply
- 5 rarity tiers with hashpower multipliers (1x–5x)
- Fully on-chain generative pixel art
- Mint fees forwarded to LPVault in the same transaction

### AgentCoin

The ERC-20 token with built-in proof-of-work mining. Follows [ERC-918](https://eips.ethereum.org/EIPS/eip-918) (Mineable Token) concepts with a dual-proof system: miners submit an SMHL format proof and a SHA-3 hash below the current difficulty target. The hash proof is the competitive mechanism; SMHL serves as lightweight format verification during mining, while newly minted Mining Rig NFTs use an LLM SMHL challenge as the strongest proof-of-agent gate.

**Key properties:**
- 21,000,000 fixed supply (18.9M mineable + 2.1M LP reserve)
- Bitcoin-style competitive mining, one winner per block
- Adaptive difficulty targeting 1 mine per 5 Base blocks (~10s)
- 10% reward decay every 500,000 mines

### LPVault

Accumulates ETH from mint fees. Once the threshold is reached, the owner can call `deployLP()` to convert ETH to USDC and deploy a full-range AGENT/USDC Uniswap V3 position, permanently locked via UNCX eternal lock.

**Key properties:**
- Owner-triggered LP deployment at 5 ETH
- AGENT/USDC pair (not AGENT/WETH)
- UNCX eternal lock, liquidity can never be withdrawn
- Deployer retains trading fee collection rights only

---

## Data Flow

```
Minter                MiningAgent              LPVault              Uniswap V3
  │                       │                       │                     │
  ├── solve SMHL ────────>│                       │                     │
  ├── mint{ETH} ─────────>│                       │                     │
  │                       ├── forward ETH ───────>│                     │
  │                       ├── mint NFT            │                     │
  │                       │                       │                     │
  │                       │       (threshold reached + owner call)      │
  │                       │                       ├── wrap ETH → WETH   │
  │                       │                       ├── swap WETH → USDC  │
  │                       │                       ├── create pool ─────>│
  │                       │                       ├── add liquidity ───>│
  │                       │                       ├── lock via UNCX     │
```

```
Miner                 AgentCoin               MiningAgent
  │                       │                       │
  ├── getMiningChallenge()│                       │
  │<── challenge + target │                       │
  ├── solve SMHL          │                       │
  ├── find nonce          │                       │
  ├── mine(nonce, sol, id)│                       │
  │                       ├── verify ownerOf(id)─>│
  │                       │<── owner address ─────│
  │                       ├── verify SMHL         │
  │                       ├── verify hash < target│
  │                       ├── mint reward to miner│
  │                       ├── rotate challenge    │
  │                       ├── adjust difficulty?  │
```

---

## Ownership Lifecycle

The live deployment retains ownership while LP deployment and follow-on liquidity operations still require `onlyOwner` calls:

| Contract | Owner-gated Functions | Lifecycle |
|----------|-----------------------|-----------|
| MiningAgent | `setAgentCoin`, `setLPVault`, `renounceOwnership` | Configuration setters are one-time |
| AgentCoin | `renounceOwnership` | No upgrade or configuration setters |
| LPVault | `setAgentCoin`, `deployLP`, `addLiquidity`, `emergencyUnwrapWeth`, `renounceOwnership` | Owner must remain available through the final liquidity operation |

Renunciation is irreversible. It must not occur before initial LP deployment, and doing it before the final intended `addLiquidity()` call would prevent remaining vault ETH from being added through the current contract interface.
