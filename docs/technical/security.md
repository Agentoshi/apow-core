# Security

AgentCoin is designed with defense-in-depth. Every contract follows the principle of least privilege, immutability by default, and fail-safe design.

---

## Ownership and Immutability

The contracts are non-upgradeable, but the live LP lifecycle still requires owner authority:

| Contract | Owner Authority | Required Lifecycle |
|----------|-----------------|--------------------|
| MiningAgent | One-time `setAgentCoin`, `setLPVault`; renunciation | Setters lock after configuration |
| AgentCoin | Renunciation only | No configuration or upgrade functions |
| LPVault | One-time `setAgentCoin`; `deployLP`, `addLiquidity`, recovery, renunciation | Owner remains required through final liquidity operation |

Renunciation is irreversible. Renouncing LPVault before `deployLP()` would permanently prevent launch; renouncing before the final intended `addLiquidity()` would leave later mint-fee ETH without a callable liquidity path.

---

## Liquidity Safety

| Protection | Mechanism |
|-----------|-----------|
| Eternal lock | UNCX `type(uint256).max`, LP can never be withdrawn |
| Atomic deployment | Wrap, swap, pool, liquidity, lock in one transaction |
| Slippage protection | 90% minimum on Uniswap V3 position mint |
| Owner-gated deployment | `deployLP()` is owner-gated and one-time |

---

## Mining Security

| Protection | Mechanism |
|-----------|-----------|
| No contracts | `msg.sender == tx.origin` on both `mint()` and `mine()` |
| One mine per block | `block.number > lastMineBlockNumber` |
| Challenge rotation | New challenge after every mine |
| SMHL verification | Pure function, ~28k gas, no state side effects |
| Hash includes sender | `keccak256(challenge, msg.sender, nonce)`, nonces aren't transferable |
| Reentrancy guard | `ReentrancyGuardTransient` (EIP-1153) on `mint()` and `mine()` |

---

## NFT Security

| Protection | Mechanism |
|-----------|-----------|
| LLM SMHL gate | Primary minting requires an SMHL solution within 20 seconds |
| 20-second window | Mint challenge expires quickly, preventing pre-computation |
| Challenge overwrite | New `getChallenge()` invalidates previous |
| Fee forwarding | Full `msg.value` sent to LPVault, nothing retained |

---

## Proof of AI Security

| Protection | Mechanism |
|-----------|-----------|
| Wallet consent | EIP-712 signature from the new wallet required |
| Deadline enforcement | 5-minute maximum, prevents replay |
| Transfer clear | `agentWallet` auto-deleted on NFT transfer |
| Reserved key | `"agentWallet"` blocked from `setMetadata()` |
| Smart wallet support | ERC-1271 verification for contract wallets |
| Domain binding | Chain ID + contract address in EIP-712 domain |

---

## Reentrancy Protection

Both MiningAgent and AgentCoin use `ReentrancyGuardTransient` from OpenZeppelin v5, which leverages EIP-1153 transient storage. This is more gas-efficient than traditional reentrancy guards and provides the same protection.

LPVault applies `nonReentrant` to `deployLP()` and `addLiquidity()`. Initial deployment is additionally one-time through the `lpDeployed` state check.

---

## Known Considerations

### `tx.origin` Check

Both `mint()` and `mine()` require `msg.sender == tx.origin`. This prevents contract-based interaction but also means:

- Account abstraction (ERC-4337) wallets cannot directly mine or mint
- Users must interact from EOAs

This is an intentional design choice. The SMHL challenge system assumes direct EOA interaction.

### Difficulty Floor

The mining target can never reach zero (floored at 1). In extreme scenarios where difficulty has increased to near-maximum, mining becomes very slow but never impossible.

### Era Decay Loop

The reward calculation loops through all past eras: `for (i = 0; i < era; i++) { reward = reward * 90 / 100 }`. At very high eras (300+), this loop becomes gas-intensive. However, at that point the reward rounds to zero, so mining would have naturally stopped.

---

## Repository Test Coverage

The contract repository includes:

- Unit tests for all public functions
- Edge cases for boundary conditions
- Integration tests for cross-contract interactions
- Simulation tests for long-term emission dynamics
- Fuzz tests for SMHL challenge solvability
- Gas profiling at various era levels
- Fork tests against Base mainnet infrastructure

The codebase is open source under the MIT license. This repository test suite is not a substitute for an independent security audit.
