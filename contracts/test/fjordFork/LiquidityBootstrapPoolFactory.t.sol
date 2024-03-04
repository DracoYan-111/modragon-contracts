// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {LiquidityBootstrapPoolFactory, PoolSettings} from "../../src/fjordFork/LiquidityBootstrapPoolFactory.sol";
import {LiquidityBootstrapPool, FixedPointMathLib, WeightedMathLib} from "../../src/fjordFork/LiquidityBootstrapPool.sol";
import {LiquidityBootstrapLib, Pool} from "../../src/fjordFork/utils/LiquidityBootstrapLib.sol";

import {TestToken} from "../../src/testToken/TestToken.sol";

contract LiquidityBootstrapPoolFactoryTest is Test {
    using LiquidityBootstrapLib for *;
    using WeightedMathLib for *;
    using FixedPointMathLib for *;

    LiquidityBootstrapPoolFactory public liquidityBootstrapPoolFactoryTest;
    LiquidityBootstrapPool public liquidityBootstrapPoolTest;
    TestToken public testToken1;
    TestToken public testToken2;

    address public initialOwner;
    uint256 public constant INITIALOWNERKEY = 0xde9be858da4a475276426320d5e9262ecfc3ba460bfac56360bfa6c4c28b4ee0;

    /**
     * @dev Sets up the test.
     */
    function setUp() external {
        initialOwner = vm.addr(INITIALOWNERKEY);

        testToken1 = new TestToken(initialOwner, "token1");
        testToken2 = new TestToken(initialOwner, "token2");

        address liquidityBootstrapPoolTestAddress = address(new LiquidityBootstrapPool(initialOwner));

        liquidityBootstrapPoolFactoryTest = new LiquidityBootstrapPoolFactory(
            liquidityBootstrapPoolTestAddress,
            initialOwner,
            initialOwner,
            0,
            0,
            0
        );
    }

    //[0x5AF6087695f26F9609a855507c2862bf81f9d08d,
    // 0x7246dA495733Bb2783a704324d25aafa9F486e46,
    // 0x3e8B6e286f78B13C35E11d567935c3aFEECb9003,
    // 0,
    // 0,
    // 309485009821345068724781055,
    // 309485009821345068724781055,
    // 309485009821345068724781055,
    // 50000000000000000,
    // 500000000000000000,
    // 1709623027,
    // 1709536627,
    // 0,
    // 0,
    // true,
    // 0x0000000000000000000000000000000000000000000000000000000000000000]

    function testCreateLiquidityBootstrapPool() external {
        vm.startPrank(initialOwner, initialOwner);
        testToken1.mint(initialOwner, 100000 ether);
        testToken1.approve(address(liquidityBootstrapPoolFactoryTest), 100000 ether);

        testToken2.mint(initialOwner, 100000 ether);
        testToken2.approve(address(liquidityBootstrapPoolFactoryTest), 100000 ether);

        PoolSettings memory poolSettings = PoolSettings(
            address(testToken1),
            address(testToken2),
            initialOwner,
            0,
            0,
            309485009821345068724781055,
            309485009821345068724781055,
            309485009821345068724781055,
            50000000000000000,
            950000000000000000,
            uint40(block.timestamp),
            uint40(block.timestamp + 1 days),
            0,
            0,
            true,
            0x0000000000000000000000000000000000000000000000000000000000000000
        );

        liquidityBootstrapPoolTest = LiquidityBootstrapPool(
            liquidityBootstrapPoolFactoryTest.createLiquidityBootstrapPool(
                poolSettings,
                100000000000000000,
                1000000000000000000,
                keccak256(abi.encode(poolSettings, block.timestamp))
            )
        );
        //console.logAddress(address(liquidityBootstrapPoolTest));
        testToken1.approve(address(liquidityBootstrapPoolTest), 100000 ether);
        testToken2.approve(address(liquidityBootstrapPoolTest), 100000 ether);

        // Pool memory pool = liquidityBootstrapPoolTest.args();
        // uint256 assetsIn = 1 ether;
        // uint256 swapFees = assetsIn.mulWad(liquidityBootstrapPoolTest.swapFee());
        // uint256 sharesOut = pool.previewSharesOut(assetsIn.rawSub(swapFees));
        // console.logUint(sharesOut);

        // // uint256 minSharesOut = 100;
        // // if (sharesOut < minSharesOut) console.logString("SlippageExceeded();");
        // // two revert ==========

        // (uint256 assetReserve, uint256 shareReserve, uint256 assetWeight, uint256 shareWeight) = pool
        //     .computeReservesAndWeights();
        // console.logUint(assetReserve);
        // console.logUint(shareReserve);
        // console.logUint(assetWeight);
        // console.logUint(shareWeight);

        // (uint256 assetReserveScaled, uint256 shareReserveScaled) = pool.scaledReserves(assetReserve, shareReserve);
        // console.logUint(assetReserveScaled);
        // console.logUint(shareReserveScaled);

        // uint256 sharesInScaled = pool.share.scaleTokenBefore(assetsIn.rawSub(swapFees));

        // console.logUint(sharesInScaled);

        // uint256 assetsOut = sharesInScaled.getAmountOut(
        //     shareReserveScaled,
        //     assetReserveScaled,
        //     shareWeight,
        //     assetWeight
        // );
        // console.logUint(assetsOut);
        // console.logUint(shareReserveScaled.mulWad(0.3 ether));

        // if (sharesInScaled > shareReserveScaled.mulWad(0.3 ether)) {
        //     console.logUint(22222222222);
        // }
        liquidityBootstrapPoolTest.swapExactAssetsForShares(0.0001 ether, 0, initialOwner);
    }
}
