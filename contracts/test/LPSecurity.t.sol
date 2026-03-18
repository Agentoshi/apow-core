// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Test} from "forge-std/Test.sol";

import {AgentCoin} from "../src/AgentCoin.sol";
import {LPVault} from "../src/LPVault.sol";
import {IMiningAgent} from "../src/interfaces/IMiningAgent.sol";

contract MockMiningAgent is ERC721, IMiningAgent {
    mapping(uint256 => uint16) public override hashpower;

    constructor() ERC721("Mock Mining Agent", "MMINER") {}

    function mint(address to, uint256 tokenId, uint16 hp) external {
        hashpower[tokenId] = hp;
        _mint(to, tokenId);
    }

    function agentURI(uint256) external pure returns (string memory) { return ""; }
    function getMetadata(uint256, string memory) external pure returns (bytes memory) { return ""; }
    function getAgentWallet(uint256) external pure returns (address) { return address(0); }
    function isAuthorizedOrOwner(address, uint256) external pure returns (bool) { return false; }
}

contract LPSecurityTest is Test {
    AgentCoin internal agentCoin;
    LPVault internal lpVault;
    MockMiningAgent internal miningAgent;

    address internal deployer = makeAddr("deployer");
    address internal user = makeAddr("user");
    address internal attacker = makeAddr("attacker");

    // Storage slots for direct state manipulation
    bytes32 internal constant SLOT_MINING_TARGET = bytes32(uint256(8));

    function setUp() public {
        miningAgent = new MockMiningAgent();

        vm.startPrank(deployer);
        lpVault = new LPVault(deployer);
        agentCoin = new AgentCoin(address(miningAgent), address(lpVault));
        lpVault.setAgentCoin(address(agentCoin));
        vm.stopPrank();

        // Mint miners to users
        miningAgent.mint(user, 1, 100);
        miningAgent.mint(attacker, 2, 100);
    }

    // =======================
    // Transfer Lock Tests
    // =======================

    function testTransfer_BlockedBeforeLP() public {
        // User mines some tokens
        _setMiningTarget(type(uint256).max);
        vm.roll(block.number + 1);

        _mine(user, 1, 0);

        uint256 balance = agentCoin.balanceOf(user);
        assertGt(balance, 0, "User should have mined tokens");

        // Try to transfer - should fail
        vm.prank(user);
        vm.expectRevert("Transfers locked until LP deployed");
        agentCoin.transfer(attacker, balance);
    }

    function testTransfer_AllowedAfterLP() public {
        // User mines tokens
        _setMiningTarget(type(uint256).max);
        vm.roll(block.number + 1);

        _mine(user, 1, 0);

        uint256 balance = agentCoin.balanceOf(user);
        assertGt(balance, 0, "User should have mined tokens");

        // Simulate LP deployment by calling setLPDeployed from vault
        vm.prank(address(lpVault));
        agentCoin.setLPDeployed();

        // Now transfer should work
        vm.prank(user);
        agentCoin.transfer(attacker, balance);

        assertEq(agentCoin.balanceOf(attacker), balance, "Transfer should succeed after LP deployed");
        assertEq(agentCoin.balanceOf(user), 0, "User balance should be zero");
    }

    function testTransfer_LPVaultExempt() public {
        // Vault has LP_RESERVE tokens from constructor
        uint256 vaultBalance = agentCoin.balanceOf(address(lpVault));
        assertEq(vaultBalance, agentCoin.LP_RESERVE(), "Vault should have LP reserve");

        // Vault can transfer before LP deployed (needed for LP creation)
        vm.prank(address(lpVault));
        agentCoin.transfer(attacker, 1000e18);

        assertEq(agentCoin.balanceOf(attacker), 1000e18, "Vault transfer should succeed");
    }

    function testMining_WorksDuringLock() public {
        _setMiningTarget(type(uint256).max);

        // Multiple mines should work
        vm.roll(100);
        _mine(user, 1, 0);

        vm.roll(101);
        _mine(user, 1, 1);

        assertGt(agentCoin.balanceOf(user), 0, "Mining should work during lock");
    }

    // =======================
    // Access Control Tests
    // =======================

    function testDeployLP_OnlyOwner() public {
        // Fund vault
        vm.deal(address(lpVault), 10 ether);

        // Non-owner cannot deploy
        vm.prank(attacker);
        vm.expectRevert();
        lpVault.deployLP(0);
    }

    function testSetLPDeployed_OnlyVault() public {
        // User cannot call setLPDeployed
        vm.prank(user);
        vm.expectRevert("Only LPVault");
        agentCoin.setLPDeployed();

        // Attacker cannot call setLPDeployed
        vm.prank(attacker);
        vm.expectRevert("Only LPVault");
        agentCoin.setLPDeployed();
    }

    function testSetLPDeployed_OnlyOnce() public {
        // First call succeeds
        vm.prank(address(lpVault));
        agentCoin.setLPDeployed();

        // Second call fails
        vm.prank(address(lpVault));
        vm.expectRevert("Already set");
        agentCoin.setLPDeployed();
    }

    // =======================
    // Attack Scenario Tests
    // =======================

    function testAttack_MiningBeforeLP() public {
        // Attacker mines tokens
        _setMiningTarget(type(uint256).max);
        vm.roll(100);

        _mine(attacker, 2, 0);

        uint256 attackerBalance = agentCoin.balanceOf(attacker);
        assertGt(attackerBalance, 0, "Attacker can mine");

        // But cannot transfer to dump
        vm.prank(attacker);
        vm.expectRevert("Transfers locked until LP deployed");
        agentCoin.transfer(user, attackerBalance);

        // Approve works but transferFrom fails
        vm.prank(attacker);
        agentCoin.approve(address(0x1234), attackerBalance);

        vm.prank(address(0x1234));
        vm.expectRevert("Transfers locked until LP deployed");
        agentCoin.transferFrom(attacker, user, attackerBalance);
    }

    function testAttack_StealLPReserve() public {
        uint256 vaultReserve = agentCoin.balanceOf(address(lpVault));
        assertEq(vaultReserve, agentCoin.LP_RESERVE());

        // Attacker tries to call setLPDeployed to unlock transfers
        vm.prank(attacker);
        vm.expectRevert("Only LPVault");
        agentCoin.setLPDeployed();

        // Even if somehow unlocked, vault must explicitly transfer
        vm.prank(address(lpVault));
        agentCoin.setLPDeployed();

        // Vault's tokens are still in vault
        assertEq(agentCoin.balanceOf(address(lpVault)), vaultReserve);

        // Attacker cannot steal them
        vm.prank(attacker);
        vm.expectRevert();
        agentCoin.transferFrom(address(lpVault), attacker, vaultReserve);
    }

    function testAttack_FrontRunDeployLP() public {
        // Attacker sees deployLP transaction in mempool
        // Tries to front-run by deploying their own pool

        // This test verifies the pool existence check
        // In a real scenario, we'd need to actually create a pool
        // For now, we verify the access control prevents unauthorized deployment

        vm.deal(address(lpVault), 10 ether);

        // Attacker cannot call deployLP
        vm.prank(attacker);
        vm.expectRevert();
        lpVault.deployLP(0);
    }

    // =======================
    // State Verification Tests
    // =======================

    function testInitialState_TransfersLocked() public {
        assertFalse(agentCoin.lpDeployed(), "LP should not be deployed initially");
        assertFalse(lpVault.lpDeployed(), "Vault LP flag should be false");
    }

    function testInitialState_VaultHasReserve() public {
        assertEq(
            agentCoin.balanceOf(address(lpVault)),
            agentCoin.LP_RESERVE(),
            "Vault should have LP reserve"
        );
    }

    function testSetLPDeployed_UpdatesState() public {
        assertFalse(agentCoin.lpDeployed());

        vm.prank(address(lpVault));
        agentCoin.setLPDeployed();

        assertTrue(agentCoin.lpDeployed());
    }

    // =======================
    // Edge Cases
    // =======================

    function testTransfer_MintingAlwaysWorks() public {
        // Even when locked, minting works (for mining)
        assertFalse(agentCoin.lpDeployed());

        _setMiningTarget(type(uint256).max);
        vm.roll(block.number + 1);

        _mine(user, 1, 0);

        assertGt(agentCoin.balanceOf(user), 0);
    }

    function testTransfer_ApproveBlockedBeforeLP() public {
        // User mines tokens
        _setMiningTarget(type(uint256).max);
        vm.roll(block.number + 1);

        _mine(user, 1, 0);

        // Approve should work
        vm.prank(user);
        agentCoin.approve(attacker, 1000e18);

        // But transferFrom should fail
        vm.prank(attacker);
        vm.expectRevert("Transfers locked until LP deployed");
        agentCoin.transferFrom(user, attacker, 1000e18);
    }

    function testTransfer_ApproveWorksAfterLP() public {
        // User mines tokens
        _setMiningTarget(type(uint256).max);
        vm.roll(block.number + 1);

        _mine(user, 1, 0);

        uint256 balance = agentCoin.balanceOf(user);

        // Deploy LP
        vm.prank(address(lpVault));
        agentCoin.setLPDeployed();

        // Approve and transferFrom should work
        vm.prank(user);
        agentCoin.approve(attacker, balance);

        vm.prank(attacker);
        agentCoin.transferFrom(user, attacker, balance);

        assertEq(agentCoin.balanceOf(attacker), balance);
    }

    // =======================
    // Full Lifecycle Test
    // =======================

    function testFullLifecycle_WithSecurity() public {
        // 1. Initial state - transfers locked
        assertFalse(agentCoin.lpDeployed());

        // 2. Users mine tokens but cannot transfer
        _setMiningTarget(type(uint256).max);

        vm.roll(100);
        _mine(user, 1, 0);

        uint256 userBalance = agentCoin.balanceOf(user);
        assertGt(userBalance, 0);

        vm.prank(user);
        vm.expectRevert("Transfers locked until LP deployed");
        agentCoin.transfer(attacker, userBalance);

        // 3. Vault has reserve
        uint256 vaultReserve = agentCoin.balanceOf(address(lpVault));
        assertEq(vaultReserve, agentCoin.LP_RESERVE());

        // 4. Only vault can transfer its reserve (for LP creation)
        vm.prank(address(lpVault));
        agentCoin.transfer(address(this), 100e18);
        assertEq(agentCoin.balanceOf(address(this)), 100e18);

        // 5. Simulate LP deployment - vault calls setLPDeployed
        vm.prank(address(lpVault));
        agentCoin.setLPDeployed();

        assertTrue(agentCoin.lpDeployed());

        // 6. Now all transfers work
        vm.prank(user);
        agentCoin.transfer(attacker, userBalance);

        assertEq(agentCoin.balanceOf(attacker), userBalance);
        assertEq(agentCoin.balanceOf(user), 0);

        // 7. New mines and transfers work normally
        vm.roll(101);
        _mine(attacker, 2, 1);

        uint256 newBalance = agentCoin.balanceOf(attacker);
        assertGt(newBalance, userBalance);

        vm.prank(attacker);
        agentCoin.transfer(user, 1e18);
        assertEq(agentCoin.balanceOf(user), 1e18);
    }

    // =======================
    // Helper Functions
    // =======================

    function _mine(address miner, uint256 tokenId, uint256 nonce) internal returns (uint256 reward) {
        (, , AgentCoin.SMHLChallenge memory challenge) = agentCoin.getMiningChallenge();
        string memory solution = _solveChallenge(challenge);
        reward = _expectedReward(tokenId);

        vm.prank(miner, miner);
        agentCoin.mine(nonce, solution, tokenId);
    }

    function _expectedReward(uint256 tokenId) internal view returns (uint256) {
        uint256 era = agentCoin.totalMines() / agentCoin.ERA_INTERVAL();
        uint256 baseReward = agentCoin.BASE_REWARD();
        for (uint256 i = 0; i < era; ++i) {
            baseReward = (baseReward * agentCoin.REWARD_DECAY_NUM()) / agentCoin.REWARD_DECAY_DEN();
        }
        return (baseReward * miningAgent.hashpower(tokenId)) / 100;
    }

    function _setMiningTarget(uint256 target) internal {
        vm.store(address(agentCoin), SLOT_MINING_TARGET, bytes32(target));
    }

    function _solveChallenge(AgentCoin.SMHLChallenge memory challenge) internal pure returns (string memory) {
        bytes memory solution = new bytes(challenge.totalLength);
        bool[] memory isSpace = new bool[](challenge.totalLength);

        // Fill with 'A' initially
        for (uint256 i = 0; i < challenge.totalLength; ++i) {
            solution[i] = bytes1(uint8(65));
        }

        // Place spaces to create word boundaries
        uint256 spacesNeeded = challenge.wordCount - 1;
        uint256 cursor = challenge.totalLength - 2;
        for (uint256 i = 0; i < spacesNeeded; ++i) {
            while (
                cursor < challenge.firstNChars || cursor == challenge.charPosition || isSpace[cursor]
                    || (cursor > 0 && isSpace[cursor - 1]) || (cursor + 1 < challenge.totalLength && isSpace[cursor + 1])
            ) {
                unchecked {
                    --cursor;
                }
            }
            solution[cursor] = bytes1(uint8(32));
            isSpace[cursor] = true;
            if (cursor > 1) {
                cursor -= 2;
            }
        }

        // Fill first N chars to match ASCII sum
        uint256 currentSum;
        for (uint256 i = 0; i < challenge.firstNChars; ++i) {
            if (i == challenge.charPosition) {
                solution[i] = bytes1(challenge.charValue);
            } else {
                solution[i] = bytes1(uint8(33));
            }
            currentSum += uint8(solution[i]);
        }

        uint256 remaining = challenge.targetAsciiSum - currentSum;
        for (uint256 i = 0; i < challenge.firstNChars && remaining > 0; ++i) {
            if (i == challenge.charPosition) {
                continue;
            }

            uint256 add = remaining > 222 ? 222 : remaining;
            solution[i] = bytes1(uint8(solution[i]) + uint8(add));
            remaining -= add;
        }

        require(remaining == 0, "Unsolvable challenge");

        if (challenge.charPosition >= challenge.firstNChars) {
            solution[challenge.charPosition] = bytes1(challenge.charValue);
        }

        return string(solution);
    }
}
