# Deployment

AgentCoin deploys to Base (Coinbase L2). The deployment sequence is critical: contracts must be configured in the correct order, and ownership must remain available throughout the required liquidity lifecycle.

---

## Prerequisites

| Requirement | Details |
|-------------|---------|
| Chain | Base mainnet (Chain ID: 8453) |
| Compiler | Solidity 0.8.26, Cancun EVM |
| Settings | `via_ir` enabled, 200 optimizer runs |
| Dependencies | OpenZeppelin Contracts v5 |
| Deployer | EOA with sufficient ETH for gas |

---

## Deploy Sequence

### Step 1: Deploy MiningAgent

```solidity
MiningAgent ma = new MiningAgent();
```

Deploys the ERC-721 mining rig contract. Starts with `nextTokenId = 1`.

### Step 2: Deploy LPVault

```solidity
LPVault vault = new LPVault(deployer);
```

Deploys the LP accumulator. The `deployer` address retains fee collection rights on the eventual Uniswap V3 position.

### Step 3: Deploy AgentCoin

```solidity
AgentCoin ac = new AgentCoin(address(ma), address(vault));
```

Deploys the ERC-20 token. This transaction:
- Sets `miningAgent` (immutable)
- Sets `lpVault` (immutable)
- Mints 2,100,000 AGENT to the LPVault
- Initializes the genesis challenge
- Sets initial mining difficulty

### Step 4: Configure MiningAgent

```solidity
ma.setLPVault(payable(address(vault)));
ma.setAgentCoin(address(ac));
```

Links the NFT contract to the vault (for fee forwarding) and the token (for dynamic `tokenURI`). Both setters are one-time only.

### Step 5: Configure LPVault

```solidity
vault.setAgentCoin(address(ac));
```

Links the vault to the token contract. One-time only.

### Step 6: Deploy and Maintain Liquidity

```solidity
vault.deployLP(minUsdcOut);
vault.addLiquidity(minUsdcOut, minAgentOut);
```

`deployLP()` is not automatic. Once LPVault contains 5 ETH, its owner must submit `deployLP(minUsdcOut)`. After initial deployment, additional mint fees can be added with owner-only `addLiquidity()` calls whenever the vault contains at least 0.1 ETH.

### Step 7: Renounce Ownership After Final Owner Operations

```solidity
ma.renounceOwnership();
ac.renounceOwnership();
vault.renounceOwnership();
```

Renunciation permanently disables every remaining owner function. Run it only after initial LP deployment and the final intended `addLiquidity()` operation. The repository's `Renounce.s.sol` refuses to proceed before initial LP deployment, but the operator must also ensure no further vault liquidity operation is needed.

---

## Post-Deploy Verification

After deployment, verify the following:

### Contract Links

```
ma.lpVault()     == address(vault)
ma.agentCoin()   == address(ac)
ac.miningAgent() == address(ma)
ac.lpVault()     == address(vault)
vault.agentCoin() == address(ac)
```

### Initial State

```
ma.nextTokenId() == 1
ma.owner()       == deployer       // retained through LP lifecycle
ac.owner()       == deployer
ac.totalMines()  == 0
ac.totalMinted() == 0
ac.balanceOf(vault) == 2_100_000e18  // LP reserve
vault.lpDeployed() == false
vault.owner()    == deployer
```

### Pricing

```
ma.getMintPrice() == 0.002 ether     // starting price
ma.MAX_SUPPLY()   == 10_000
```

### Mining

```
ac.miningTarget()     == type(uint256).max >> 16  // easy initial difficulty
ac.challengeNumber()  == keccak256("AgentCoin Genesis")
```

---

## Storage Layout

Constants don't use storage slots. Verify with:

```bash
forge inspect MiningAgent storage-layout
forge inspect AgentCoin storage-layout
forge inspect LPVault storage-layout
```

---

## Development

```bash
# Install dependencies
cd contracts && forge install

# Run all tests (231)
forge test

# Run fork tests against Base mainnet
forge test --match-path test/LPVaultFork.t.sol --fork-url $BASE_RPC

# Gas report
forge test --gas-report

# Inspect storage
forge inspect MiningAgent storage-layout
```
