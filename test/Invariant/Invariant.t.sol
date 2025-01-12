// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import { PoolFactory } from "src/PoolFactory.sol";
import { TSwapPool } from "src/TSwapPool.sol";
import { ERC20Mock } from "../mocks/ERC20Mock.sol";
import {Handler} from "./Handler.t.sol";

contract Invariant is StdInvariant,Test{
    ERC20Mock weth;
    ERC20Mock poolToken;

    PoolFactory factory;
    TSwapPool pool;//poolToken/WETH

    int256 constant STARTING_X = 100e18;//starting poolToken
    int256 constant STARTING_Y = 50e18;//starting weth

    Handler handler;

    function setUp() public {
        weth = new ERC20Mock();
        poolToken = new ERC20Mock();
        factory = new PoolFactory(address(weth));
        pool = TSwapPool(factory.createPool(address(poolToken)));

        //Create initial x and y balances
        poolToken.mint(address(this),uint256(STARTING_X));
        weth.mint(address(this),uint256(STARTING_Y));

        poolToken.approve(address(pool),type(uint256).max);
        weth.approve(address(pool),type(uint256).max);

        //Deposit into the pool,give the starting X & Y balances
        pool.deposit(uint256(STARTING_Y),uint256(STARTING_Y),uint256(STARTING_X),uint64(block.timestamp));

        handler = new Handler(pool);
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = handler.deposit.selector;
        selectors[1] = handler.swapPoolTokenForWethBasedOnOutputWeth.selector;
        targetSelector(FuzzSelector({addr:address(handler),selectors:selectors}));
        targetContract(address(handler));
    }

    function statefulFuzz_constantProductFormulaStaysTheSameX() public {
        assertEq(handler.actualDeltaX(),handler.expectedDeltaX());
    }

    function statefulFuzz_constantProductFormulaStaysTheSameY() public {
        assertEq(handler.actualDeltaY(),handler.expectedDeltaY());
    }
}
