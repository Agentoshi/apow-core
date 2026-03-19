// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {console, Script} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {LPVault} from "../src/LPVault.sol";

interface IQuoterV2 {
    struct QuoteExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    function quoteExactInputSingle(QuoteExactInputSingleParams memory params)
        external
        returns (uint256 amountOut, uint160 sqrtPriceX96After, uint32 initializedTicksCrossed, uint256 gasEstimate);
}

/// @title AddLiquidity — Add accumulated ETH to existing UNCX-locked LP position
/// @notice Swaps vault ETH → USDC → half to AGENT, then increases liquidity via UNCX.
///         Callable multiple times before ownership renunciation.
contract AddLiquidity is Script {
    address public constant WETH = 0x4200000000000000000000000000000000000006;
    address public constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address public constant QUOTER_V2 = 0x3d4e44Eb1374240CE5F1B871ab261CD16335B76a;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);

        address lpVaultAddr = vm.envAddress("LP_VAULT_ADDRESS");
        LPVault lpVault = LPVault(payable(lpVaultAddr));

        console.log("=== AddLiquidity Pre-flight ===");
        console.log("Deployer:", deployer);
        console.log("LPVault:", lpVaultAddr);
        console.log("Vault balance (wei):", lpVaultAddr.balance);

        // Pre-flight checks
        require(block.chainid == 8453, "Not Base mainnet");
        require(lpVault.owner() == deployer, "Not vault owner");
        require(lpVault.lpDeployed(), "LP not deployed");
        require(lpVaultAddr.balance >= lpVault.ADD_LIQUIDITY_THRESHOLD(), "Below threshold");

        // Quote WETH → USDC via QuoterV2 (full vault balance)
        IQuoterV2.QuoteExactInputSingleParams memory wethQuote = IQuoterV2.QuoteExactInputSingleParams({
            tokenIn: WETH,
            tokenOut: USDC,
            amountIn: lpVaultAddr.balance,
            fee: 3000,
            sqrtPriceLimitX96: 0
        });

        (uint256 quotedUsdc,,,) = IQuoterV2(QUOTER_V2).quoteExactInputSingle(wethQuote);

        // Quote USDC → AGENT via QuoterV2 (half the USDC)
        address agentCoinAddr = address(lpVault.agentCoin());
        uint256 halfUsdc = quotedUsdc / 2;

        IQuoterV2.QuoteExactInputSingleParams memory agentQuote = IQuoterV2.QuoteExactInputSingleParams({
            tokenIn: USDC,
            tokenOut: agentCoinAddr,
            amountIn: halfUsdc,
            fee: 3000,
            sqrtPriceLimitX96: 0
        });

        (uint256 quotedAgent,,,) = IQuoterV2(QUOTER_V2).quoteExactInputSingle(agentQuote);

        // 3% slippage tolerance on both swaps
        uint256 minUsdcOut = quotedUsdc * 97 / 100;
        uint256 minAgentOut = quotedAgent * 97 / 100;

        console.log("Quoted USDC out:", quotedUsdc);
        console.log("Quoted AGENT out:", quotedAgent);
        console.log("Min USDC out (3% slippage):", minUsdcOut);
        console.log("Min AGENT out (3% slippage):", minAgentOut);

        vm.startBroadcast(pk);
        lpVault.addLiquidity(minUsdcOut, minAgentOut);
        vm.stopBroadcast();

        console.log("=== LIQUIDITY ADDED ===");
        console.log("Remaining vault balance:", lpVaultAddr.balance);
    }
}
