// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { Test } from "forge-std/Test.sol";
import {stdInvariant} from "forge-std/StdInvariant.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {PoolFactory} from "../../../src/PoolFactory.sol";
import {TSwapPool} from "../../../src/TSwapPool.sol";
import {Handler} from "./Handler.t.sol";

contract InvariantTest is Test {

    // these pools have 2 assets
    ERC20Mock poolToken;
    ERC20Mock weth;

    // we are need the contracts
    PoolFactory factory;
    TSwapPool pool; // poolToken / weth
    Handler handler;

    int256 constant STARTING_X = 100E18; // STARTING ERC20 / POOL TOKEN
    int256 constant STARTING_Y = 50E18; // STARTING WETH 
}
    function setUp() public {
        poolToken = new ERC20Mock();
        weth = new ERC20Mock();
        factory = new PoolFactory(address(weth));
        pool = factory.createPool(address(poolToken));

        // create those x & y initial balances
        poolToken.mint(address(this), uint256(STARTING_X));
        weth.mint(address(this), uint256(STARTING_Y));

        poolToken.approve(address(pool), type(uint256).max);
        weth.approve(address(pool), type(uint256).max);

        // deposit into the pool, give the starting X & Y balance
        // deposit into the pool, give the starting X & Y balance
        pool.addLiquidity(
            uint256(STARTING_X),       // Cantidad base de fichas de liquidez (poolToken)
            uint256(STARTING_X),       // Máximo de poolToken a depositar
            uint256(STARTING_Y),       // Cantidad exacta de WETH a depositar
            uint64(block.timestamp)    // Límite de tiempo (Deadline)
        );

        handler = new Handler(pool);
        bytes4[] memory Selectors = new bytes4[](2);
        Selectors[0] = handler.deposit.selector;
        Selectors[1] = handler.swapPoolTokenForWethBasedOnOutputWeth.selector;

        targetSelector(fuzzSelector({addr: address(handler), selectors: Selectors}));

        targetContract(address(handler));

        function statefulFuzz_constantProductFormulaStaysTheSame() public {
    // assert() // ????????
    // The change in the pool size of WETH should follow this funciton:
    // Δx = (β/(1-β)) * x
    // ?????
    // In a handler
    // actual delta X == Δx = (β/(1-β)) * x
    }

    assertEq(handler.actualDeltaX(), handler.expectedDeltaX());
}
