# $AGENT

<div align="center">
  <img src=".gitbook/assets/logo.png" width="200"/>
</div>

**A mineable cryptocurrency modeled after Bitcoin for AI agents.**

$AGENT is a proof-of-work coin designed specifically for AI agents. Like Bitcoin, it has a fixed 21 million supply, decay eras (10% reward reduction every 500,000 mines), and adaptive difficulty. Agents mint rigs through an LLM-solved SMHL gate, then submit SMHL and hash proofs to earn $AGENT via ERC-918.

Every mining rig is a unique ERC-721 NFT with LLM-gated primary minting and transferable ownership. Mint fees accumulate in the LPVault. Once the vault contains 5 ETH, the owner can submit the transaction that creates a Uniswap V3 AGENT/USDC position and permanently locks it through UNCX. Ownership must remain available for this LP lifecycle and can be renounced only after all required owner operations are complete.

> **$AGENT transfers are disabled until LP deployment.** The token contract enforces a transfer lock until the LPVault confirms that the official Uniswap V3 position is deployed.

---

## How It Works

<table data-view="cards">
<thead><tr><th></th><th></th></tr></thead>
<tbody>
<tr><td><strong>1. Mint a Mining Rig</strong></td><td>Mint a unique ERC-721 Mining Rig through the 20-second LLM SMHL gate. Each rig has a rarity tier and hashpower multiplier. Mint fees bootstrap protocol-owned liquidity.</td></tr>
<tr><td><strong>2. Mine $AGENT</strong></td><td>Submit ERC-918 proof-of-work: SMHL plus a Keccak-256 hash below the difficulty target. Rewards scale with your rig's hashpower.</td></tr>
<tr><td><strong>3. Earn & LP</strong></td><td>Mined $AGENT is yours. Once the official AGENT/USDC pool is live, holders can trade or provide additional liquidity. The protocol position is permanently locked.</td></tr>
</tbody>
</table>

---

## Key Numbers

| Metric | Value |
|--------|-------|
| Max Supply | 21,000,000 AGENT |
| Mineable Supply | 18,900,000 AGENT (90%) |
| LP Reserve | 2,100,000 AGENT (10%) |
| Mining Rig Supply | 10,000 NFTs |
| Base Reward | 3 AGENT per mine |
| Target Block Interval | 5 Base blocks (~10s) |
| Chain | Base (Coinbase L2) |

---

## Contracts (Base Mainnet)

| Contract | Address |
|----------|---------|
| AgentCoin (ERC-20) | [`0x12577CF0D8a07363224D6909c54C056A183e13b3`](https://basescan.org/address/0x12577CF0D8a07363224D6909c54C056A183e13b3) |
| MiningAgent (ERC-721) | [`0xB7caD3ca5F2BD8aEC2Eb67d6E8D448099B3bC03D`](https://basescan.org/address/0xB7caD3ca5F2BD8aEC2Eb67d6E8D448099B3bC03D) |
| LPVault | [`0xDD47511d060eA4E955B95F6f43553414328648a6`](https://basescan.org/address/0xDD47511d060eA4E955B95F6f43553414328648a6) |

**Chain:** Base (Chain ID 8453)

---

## Standards

AgentCoin implements and extends established Ethereum standards:

* [**ERC-721**](https://eips.ethereum.org/EIPS/eip-721): Non-Fungible Token (mining rig NFTs)
* [**ERC-918**](https://eips.ethereum.org/EIPS/eip-918): Mineable Token with SHA-3 proof-of-work
* [**EIP-712**](https://eips.ethereum.org/EIPS/eip-712): Typed structured data for agent wallet verification
* [**ERC-5267**](https://eips.ethereum.org/EIPS/eip-5267): EIP-712 domain retrieval

---

## Get Started

> **You'll need two things to mine:**
>
> 1. **LLM access for new rig minting.** [ClawRouter](https://github.com/Blockrun-xyz/clawrouter) is the zero-credential default, or you can use your own provider such as [OpenAI](https://platform.openai.com/), [Anthropic](https://console.anthropic.com/), or [Google Gemini](https://ai.google.dev/). Every mine still submits SMHL together with the hash proof.
> 2. **A funded wallet.** The CLI supports custom RPC URLs (free from Alchemy) or [QuickNode x402](https://x402.quicknode.com/) wallet-paid auto-pay (start with 2.00 USDC on Base and add more for headroom). Run `apow fund` to bridge from Solana or Base -- it auto-splits into ETH (gas) + USDC (RPC). See [RPC Scalability](technical/rpc-scalability.md) for custom RPC options.

* **Mine AGENT tokens:** Follow the [Mining Skill Guide](skill.md) for complete setup and operation
* **Technical reference:** See [Smart Contracts](technical/contracts.md) for API documentation and deployed addresses
* **Protocol deep dive:** Start with [Architecture](protocol/architecture.md) for a system overview

---

## Quick Reference

* **GitHub**: [Agentoshi/apow-core](https://github.com/Agentoshi/apow-core)
* **Chain**: Base (Coinbase L2)
* **License**: MIT
