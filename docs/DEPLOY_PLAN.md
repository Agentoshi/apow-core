# APoW Protocol — Mainnet Deployment Runbook

**Operator:** Agentoshi (deployer wallet)
**Network:** Base Mainnet (Chain ID: 8453)
**One-time use. Irreversible after Step 8.**

---

## Prerequisites

- [ ] **Foundry** installed (`forge`, `cast`, `anvil` available in PATH)
- [ ] **Node.js** 18+ via nvm, with the miner CLI built (`cd miner && npm run build`)
- [ ] **Deployer wallet** funded with sufficient ETH on Base:
  - ~0.01 ETH for contract deployments (3 contracts + cross-wiring)
  - ~0.002 ETH for smoke-test mint
  - Gas for DeployLP and Renounce scripts
  - Total: ~0.05 ETH minimum in deployer wallet (excludes LP funding)
- [ ] **Basescan API key** for contract verification
- [ ] **LLM API key** for miner SMHL challenges (OpenAI, Anthropic, or local Ollama)
- [ ] All contracts compiled and tests passing: `cd contracts && forge build && forge test`

---

## Environment Setup

Create `.env` in the project root (never commit this file):

```bash
# RPC
BASE_RPC=https://mainnet.base.org

# Deployer wallet
PRIVATE_KEY=<deployer-private-key>

# Basescan verification
BASESCAN_API_KEY=<basescan-api-key>

# Set after Step 1 (contract deployment)
MINING_AGENT_ADDRESS=
AGENT_COIN_ADDRESS=
LP_VAULT_ADDRESS=

# Miner client (for smoke tests in Steps 3-4)
MINER_PRIVATE_KEY=<same-as-PRIVATE_KEY-for-smoke-test>
MINER_RPC_URL=https://mainnet.base.org
LLM_PROVIDER=openai
LLM_MODEL=gpt-4o-mini
OPENAI_API_KEY=<openai-key>
```

Source the env before running forge scripts:

```bash
source .env
```

---

## Deployment Steps

| Step | Action | Verification |
|------|--------|--------------|
| 1 | Deploy contracts | All 3 contracts deployed, cross-wired, 2.1M AGENT in vault |
| 2 | Verify on Basescan | All contracts verified, source readable |
| 3 | Smoke test: mint 1 NFT | Token #1 minted, fee forwarded to vault |
| 4 | Smoke test: mine 1 block | 1 mine confirmed, AGENT earned, transfers still locked |
| 5 | Fund LP vault | Vault balance >= 4.93 ETH |
| 6 | Deploy liquidity pool | LP deployed, pool created, UNCX locked, transfers unlocked |
| 7 | Verify LP deployment | Uniswap pool visible, UNCX eternal lock confirmed |
| **8** | **RENOUNCE OWNERSHIP** | **All 3 owners == address(0). POINT OF NO RETURN.** |
| 9 | Verify immutability | All admin functions permanently disabled |
| 10 | Publish and announce | Addresses discoverable, miner defaults updated |

---

### Step 1 — Deploy Contracts

```bash
cd contracts
forge script script/Deploy.s.sol \
  --rpc-url $BASE_RPC \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY
```

This deploys three contracts in order:
1. **LPVault** — receives mint fees, holds 2.1M AGENT LP reserve
2. **MiningAgent** — ERC-721 miner NFTs (SMHL challenge + mint)
3. **AgentCoin** — ERC-20 AGENT token (mints LP_RESERVE to LPVault in constructor)

Then cross-wires them:
- `miningAgent.setLPVault(lpVault)`
- `miningAgent.setAgentCoin(agentCoin)`
- `lpVault.setAgentCoin(agentCoin)`

**Verification (automatic in script):**
- `agentCoin.lpDeployed() == false`
- `lpVault.lpDeployed() == false`
- `AGENT.balanceOf(lpVault) == 2,100,000e18`
- All ownership == deployer
- All cross-pointers correct

**Save the deployed addresses immediately:**
```bash
export MINING_AGENT_ADDRESS=<from-output>
export AGENT_COIN_ADDRESS=<from-output>
export LP_VAULT_ADDRESS=<from-output>
```

Update `.env` with these addresses.

---

### Step 2 — Verify on Basescan

If `--verify` succeeded in Step 1, check each contract on Basescan:
- `https://basescan.org/address/$AGENT_COIN_ADDRESS#code`
- `https://basescan.org/address/$MINING_AGENT_ADDRESS#code`
- `https://basescan.org/address/$LP_VAULT_ADDRESS#code`

**MiningAgent** uses the `MinerArt` library — Basescan needs the library link to verify. If auto-verify failed:

```bash
forge verify-contract $MINING_AGENT_ADDRESS MiningAgent \
  --rpc-url $BASE_RPC \
  --etherscan-api-key $BASESCAN_API_KEY \
  --libraries src/lib/MinerArt.sol:MinerArt:<library-address>
```

**Verification:**
- [ ] All 3 contracts show "Contract Source Code Verified" on Basescan
- [ ] Read/Write tabs functional on each contract

---

### Step 3 — Smoke Test: Mint 1 NFT

```bash
agentcoin mint
```

This requests an SMHL challenge from MiningAgent, solves it via LLM, and submits `mint()` with the required ETH fee (0.002 ETH for token #1).

**Verification:**
```bash
# Token #1 exists and is owned by deployer
cast call $MINING_AGENT_ADDRESS "ownerOf(uint256)" 1 --rpc-url $BASE_RPC

# Mint fee forwarded to vault
cast balance $LP_VAULT_ADDRESS --rpc-url $BASE_RPC

# Next token ID incremented
cast call $MINING_AGENT_ADDRESS "nextTokenId()" --rpc-url $BASE_RPC
# Expected: 2
```

---

### Step 4 — Smoke Test: Mine 1 Block

```bash
agentcoin mine 1
```

Then press Ctrl+C after 1 successful mine.

**Verification:**
```bash
# Total mines incremented
cast call $AGENT_COIN_ADDRESS "totalMines()" --rpc-url $BASE_RPC
# Expected: 1

# AGENT minted to deployer (3 AGENT base * hashpower/100)
cast call $AGENT_COIN_ADDRESS "balanceOf(address)" $DEPLOYER_ADDRESS --rpc-url $BASE_RPC

# Transfers still locked (this should REVERT)
cast send $AGENT_COIN_ADDRESS "transfer(address,uint256)" 0x000000000000000000000000000000000000dEaD 1 \
  --rpc-url $BASE_RPC --private-key $PRIVATE_KEY 2>&1 | grep "Transfers locked"
# Expected: revert with "Transfers locked until LP deployed"
```

---

### Step 5 — Fund LP Vault

The vault needs >= 4.93 ETH (4.9 ETH LP_DEPLOY_THRESHOLD + 0.03 ETH UNCX_FLAT_FEE).

**Option A:** Wait for organic mint fees to accumulate (slow).

**Option B:** Fund directly (recommended for launch):
```bash
cast send $LP_VAULT_ADDRESS \
  --value 4.93ether \
  --rpc-url $BASE_RPC \
  --private-key $PRIVATE_KEY
```

**Verification:**
```bash
cast balance $LP_VAULT_ADDRESS --rpc-url $BASE_RPC
# Must be >= 4930000000000000000 (4.93 ETH in wei)
```

---

### Step 6 — Deploy Liquidity Pool

```bash
cd contracts
forge script script/DeployLP.s.sol \
  --rpc-url $BASE_RPC \
  --broadcast
```

This script:
1. Quotes WETH -> USDC swap via Uniswap V3 QuoterV2
2. Calls `lpVault.deployLP(minUsdcOut)` which:
   - Wraps vault ETH to WETH (minus 0.03 UNCX fee)
   - Swaps all WETH -> USDC
   - Creates AGENT/USDC Uniswap V3 pool (0.3% fee tier)
   - Mints full-range LP position (tick -887220 to 887220)
   - Calls `agentCoin.setLPDeployed()` — **unlocks all AGENT transfers**
   - Locks LP NFT in UNCX with `unlockDate = type(uint256).max` (eternal)
   - UNCX lock params: `owner = deployer`, `collectAddress = deployer`

**Verification (automatic in script):**
- `lpVault.lpDeployed() == true`
- `lpVault.positionTokenId() > 0`

---

### Step 7 — Verify LP Deployment

```bash
# LP deployed flag
cast call $LP_VAULT_ADDRESS "lpDeployed()" --rpc-url $BASE_RPC
# Expected: true

# AgentCoin transfer lock lifted
cast call $AGENT_COIN_ADDRESS "lpDeployed()" --rpc-url $BASE_RPC
# Expected: true

# Test a transfer (should succeed now)
cast send $AGENT_COIN_ADDRESS "transfer(address,uint256)" $LP_VAULT_ADDRESS 1 \
  --rpc-url $BASE_RPC --private-key $PRIVATE_KEY
# Expected: success (no revert)
```

**External verification:**
- [ ] Uniswap pool visible: `https://app.uniswap.org/explore/pools/base/<pool-address>`
- [ ] UNCX lock visible: `https://app.uncx.network/lockers/v3/base/lock/<lock-id>`
- [ ] Lock shows `unlockDate = type(uint256).max` (eternal / never unlocks)
- [ ] AGENT is tradeable on Uniswap

---

### Step 8 — RENOUNCE OWNERSHIP (POINT OF NO RETURN)

```
##############################################################
#                                                            #
#   WARNING: THIS STEP IS IRREVERSIBLE.                      #
#                                                            #
#   After execution, no admin functions can ever be called.  #
#   No rollback. No upgrades. No recovery. By design.        #
#                                                            #
#   Triple-check all cross-pointers before proceeding.       #
#                                                            #
##############################################################
```

**Pre-renounce checklist:**
- [ ] `lpVault.lpDeployed() == true` (renounce script enforces this — protects against bricking)
- [ ] All 3 contracts have correct cross-pointers (renounce script verifies)
- [ ] LP position is locked in UNCX (eternal)
- [ ] AGENT transfers work
- [ ] Mining works
- [ ] Minting works

```bash
cd contracts
forge script script/Renounce.s.sol \
  --rpc-url $BASE_RPC \
  --broadcast
```

The script renounces ownership on all three contracts:
- `miningAgent.renounceOwnership()`
- `agentCoin.renounceOwnership()`
- `lpVault.renounceOwnership()`

**Verification (automatic in script):**
- `miningAgent.owner() == address(0)`
- `agentCoin.owner() == address(0)`
- `lpVault.owner() == address(0)`

---

### Step 9 — Verify Immutability

Attempt every admin function — all must revert:

```bash
# MiningAgent admin functions
cast send $MINING_AGENT_ADDRESS "setLPVault(address)" 0x0000000000000000000000000000000000000001 \
  --rpc-url $BASE_RPC --private-key $PRIVATE_KEY 2>&1 | grep -i "revert"

cast send $MINING_AGENT_ADDRESS "setAgentCoin(address)" 0x0000000000000000000000000000000000000001 \
  --rpc-url $BASE_RPC --private-key $PRIVATE_KEY 2>&1 | grep -i "revert"

# LPVault admin functions
cast send $LP_VAULT_ADDRESS "setAgentCoin(address)" 0x0000000000000000000000000000000000000001 \
  --rpc-url $BASE_RPC --private-key $PRIVATE_KEY 2>&1 | grep -i "revert"

# AgentCoin — owner functions (renounceOwnership itself, transferOwnership)
cast send $AGENT_COIN_ADDRESS "renounceOwnership()" \
  --rpc-url $BASE_RPC --private-key $PRIVATE_KEY 2>&1 | grep -i "revert"
```

**Verification:**
- [ ] Every call above reverts with `OwnableUnauthorizedAccount`
- [ ] Protocol is fully immutable — no human can change any parameter

---

### Step 10 — Publish and Announce

1. **Update apow.io** with deployed contract addresses:
   - AgentCoin: `$AGENT_COIN_ADDRESS`
   - MiningAgent: `$MINING_AGENT_ADDRESS`
   - LPVault: `$LP_VAULT_ADDRESS`

2. **Update miner defaults** so users don't need to configure addresses manually

3. **Publish addresses** to all discovery channels (docs, socials, etc.)

---

## Post-Deploy Verification Checklist

Run this full sweep after all 10 steps are complete:

```bash
echo "=== Contract State ==="
echo "AgentCoin:"
cast call $AGENT_COIN_ADDRESS "owner()" --rpc-url $BASE_RPC
cast call $AGENT_COIN_ADDRESS "lpDeployed()" --rpc-url $BASE_RPC
cast call $AGENT_COIN_ADDRESS "totalMines()" --rpc-url $BASE_RPC
cast call $AGENT_COIN_ADDRESS "totalSupply()" --rpc-url $BASE_RPC

echo "MiningAgent:"
cast call $MINING_AGENT_ADDRESS "owner()" --rpc-url $BASE_RPC
cast call $MINING_AGENT_ADDRESS "nextTokenId()" --rpc-url $BASE_RPC
cast call $MINING_AGENT_ADDRESS "lpVault()" --rpc-url $BASE_RPC
cast call $MINING_AGENT_ADDRESS "agentCoin()" --rpc-url $BASE_RPC

echo "LPVault:"
cast call $LP_VAULT_ADDRESS "owner()" --rpc-url $BASE_RPC
cast call $LP_VAULT_ADDRESS "lpDeployed()" --rpc-url $BASE_RPC
cast call $LP_VAULT_ADDRESS "positionTokenId()" --rpc-url $BASE_RPC
cast call $LP_VAULT_ADDRESS "deployer()" --rpc-url $BASE_RPC
```

**Expected final state:**
- All `owner()` calls return `0x0000000000000000000000000000000000000000`
- `lpDeployed == true` on both AgentCoin and LPVault
- All cross-pointers resolve correctly
- Minting works (public can mint miners)
- Mining works (miners earn AGENT)
- AGENT is freely transferable and tradeable on Uniswap
- LP is eternally locked in UNCX

---

## Emergency Procedures (Before Step 8 ONLY)

After Step 8, there are no emergency procedures. The protocol is immutable by design.

### Stuck WETH in LPVault (DeployLP partial failure)

If `deployLP()` fails after wrapping ETH but before completing:

```bash
cast send $LP_VAULT_ADDRESS "emergencyUnwrapWeth()" \
  --rpc-url $BASE_RPC --private-key $PRIVATE_KEY
```

This unwraps WETH back to ETH in the vault. Only callable by owner before LP is deployed.

### Wrong cross-pointer detected

If a cross-pointer is wrong after Step 1, **do not proceed**. The `setX()` functions are one-shot (enforced by `require(x == address(0), "Already set")`). You must redeploy from scratch.

### LP vault funded but wrong amounts

If the vault has ETH but you need to abort before Step 6: the owner can call `emergencyUnwrapWeth()` to recover any wrapped ETH, but raw ETH in the vault contract has no withdrawal function. It can only flow out through `deployLP()`. Plan carefully.

### Rollback

- **Before Step 6:** Redeploy all contracts from Step 1. Previous contracts become dead (no ETH recovery from vault).
- **Before Step 8:** You still have admin access. Assess the situation and decide whether to proceed or redeploy.
- **After Step 8:** No rollback possible. This is intentional. The protocol is trustless precisely because nobody — including Agentoshi — can change it.

---

## Important Notes

- **Agentoshi wallet is NOT destroyed.** It retains UNCX fee collection rights only. The wallet continues to collect trading fees from the LP position via the UNCX dashboard.

- **Token #1 + ~3 AGENT remain in Agentoshi's wallet.** This is a negligible amount from the smoke test (Step 3-4). No special handling needed.

- **Agentoshi never mines again after Step 4.** The smoke test is the only time the deployer mines. All subsequent mining is by public participants.

- **Fee collection procedure:** UNCX dashboard -> connect deployer wallet -> "Collect Fees". This is the deployer's only ongoing interaction with the protocol. The UNCX lock params set `owner = deployer` and `collectAddress = deployer`, granting permanent fee collection rights even after ownership renunciation.

- **Rollback is only possible before Step 8.** After renounce: no rollback, no admin access, no upgrades. This is the entire point of the protocol — trustless immutability.

- **The Renounce script has a safety check.** It requires `lpVault.lpDeployed() == true` before executing. This prevents accidentally bricking the protocol by renouncing before LP deployment (since `deployLP()` requires `onlyOwner`).
