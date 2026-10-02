// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import {Test,console2} from "forge-std/Test.sol";
import {TSwapPool} from "../../../src/TSwapPool.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

contract Handler is Test {
    TSwapPool pool;
    ERC20Mock weth;
    ERC20Mock poolToken;

    address liquidityProvider = makeAddr("lp");

    //Ghost variables
    int256 startingY; // actual balance of weth
    int256 startingX; // actual balance of poolToken
    int256 expectedDeltaY; // expected balance of weth
    int256 expectedDeltaX; // expected balance of poolToken
    int256 actualDeltaY;
    int256 actualDeltaX;

    constructor(TSwapPool _pool) {
        pool = _pool;
        weth = ERC20Mock(pool.getWeth());
        poolToken = ERC20Mock(pool.getPoolToken());
    }

    function swapPoolTokenForWethBasedOnOutputWeth(uint256 outputWeth) public {
        outputWeth = bound(outputWeth, 0, type(uint64).max);
        if (outputWeth >= weth.balanceOf(address(pool))) {
            return;
        }
        // ΔX
        // Δx = (B / (1-B)) * x
        uint256 poolTokenAmount = pool.getInputAmountBasedOnOutput(
            outputWeth, 
            poolToken.balanceOf(address(pool)), 
            weth.balanceOf(address(pool))
            );

            if (poolTokenAmount >=type(uint64).max) {
                return;
    }

    startingY = int256(weth.balanceOf(address(this)));
    startingX = int256(poolToken.balanceOf(address(this)));
    expectedDeltaY = int256(outputWeth);
    expectedDeltaX = int256(poolTokenAmount);

    // deposit, swap exactOutput
    function deposit(uint256 wethAmount) public {
        // let´s make sure it´s a "reasonable amount"
        // avoid weird overflows errors
        wethAmount = bound(wethAmount, 0, type(uint64).max);

        startingY = int256(weth.balanceOf(address(this)));
        startingX = int256(poolToken.balanceOf(address(this)));
        expectedDeltaY = int256(weth.amount);
        expectedDeltaX = int256(pool.getPoolTokensToDepositBasedOnWeth(wethAmount));

        // deposit
        vm.prank(liquidityProvider);
        weth.mint(liquidityProvider, wethAmount);
        poolToken.mint(liquidityProvider, uint256(expectedDeltaX));
        weth.approve(address(pool), type(uint256).max);
        poolToken.approve(address(pool), type(uint256).max);

        pool.deposit(wethAmount, 0,  expectedDeltaX, uint64(block.timestamp));
        vm.stopPrank();

         //actual
        uint256 endingY = weth.balanceOf(address(this));
        uint256 endingX = poolToken.balanceOf(address(this));

        actualDeltaY = int256(endingY) - int256(startingY);
        actualDeltaX = int256(endingX) - int256(startingX);
}
}