// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

import {LiquidityBootstrapPoolFactory, PoolSettings} from "../../src/fjordFork/LiquidityBootstrapPoolFactory.sol";
import {LiquidityBootstrapPool, FixedPointMathLib, WeightedMathLib} from "../../src/fjordFork/LiquidityBootstrapPoolNew.sol";
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

        address liquidityBootstrapPoolTestAddress = address(new LiquidityBootstrapPool());

        liquidityBootstrapPoolFactoryTest = new LiquidityBootstrapPoolFactory(
            liquidityBootstrapPoolTestAddress,
            initialOwner,
            initialOwner,
            0,
            0,
            0
        );
    }

    function testCreateLiquidityBootstrapPool() external {
        vm.startPrank(initialOwner, initialOwner);
        testToken1.mint(initialOwner, 100000 ether);
        testToken1.approve(address(liquidityBootstrapPoolFactoryTest), 100000 ether);

        testToken2.mint(initialOwner, 100000 ether);
        testToken2.approve(address(liquidityBootstrapPoolFactoryTest), 100000 ether);

        PoolSettings memory poolSettings = PoolSettings(
            address(testToken1), // A token
            address(testToken2), // B token
            initialOwner, // owner
            0, // virtua A token
            0, // virtua B token
            309485009821345068724781055, // max B token price(default)
            309485009821345068724781055, // max B token out(default)
            309485009821345068724781055, // max A token in(default)
            0.05 ether, // start ratio(percentage)
            0.5 ether, // end ratio(percentage)
            uint40(block.timestamp), // start time
            uint40(block.timestamp + 1 days), //end time
            0, // default
            0, // default
            true, // sell Allowed
            0x0000000000000000000000000000000000000000000000000000000000000000 //whitelist
        );

        liquidityBootstrapPoolTest = LiquidityBootstrapPool(
            liquidityBootstrapPoolFactoryTest.createLiquidityBootstrapPool(
                poolSettings,
                1000 ether, // B token amount
                10 ether, // A token amount
                keccak256(abi.encode(poolSettings, block.timestamp))
            )
        );

        testToken1.approve(address(liquidityBootstrapPoolTest), 100000 ether);
        testToken2.approve(address(liquidityBootstrapPoolTest), 100000 ether);

        console.logString("==================");

        console.logUint(liquidityBootstrapPoolTest.previewAssetsIn(10 ether));

        vm.warp(block.timestamp + 1000);

        console.logString("==================1");

        uint256 assetsIn = liquidityBootstrapPoolTest.previewAssetsIn(10 ether);
        // console.logString("Buy 10ether assets need:");
        console.logUint(assetsIn);

        uint256 sharesIn = liquidityBootstrapPoolTest.previewSharesIn(assetsIn);
        console.logUint(sharesIn);

        uint256 assetsOut = liquidityBootstrapPoolTest.previewAssetsOut(10 ether);
        console.logUint(assetsOut);

        uint256 sharesOut = liquidityBootstrapPoolTest.previewSharesOut(assetsOut);
        console.logUint(sharesOut);
        //===========================================================================

        vm.warp(block.timestamp + 2000);

        console.logString("==================2");
        console.logUint(liquidityBootstrapPoolTest.previewAssetsIn(10 ether));

        // uint256 userShares = liquidityBootstrapPoolTest.purchasedShares(initialOwner);
        // // console.logString("Amount before purchase");
        // console.logUint(userShares);

        // Buy shares
        liquidityBootstrapPoolTest.swapExactAssetsForShares(assetsIn, sharesOut, initialOwner);

        uint256 userShares1 = liquidityBootstrapPoolTest.purchasedShares(initialOwner);
        //console.logString("Amount after purchase");
        console.logUint(userShares1);

        vm.warp(block.timestamp + 3000);

        console.logString("==================3");
        console.logUint(liquidityBootstrapPoolTest.purchasedShares(initialOwner));
        uint256 userShares3 = userShares1;
        console.logUint(userShares3);

        //uint256 assetsOut1 = liquidityBootstrapPoolTest.previewAssetsOut(userShares1);
        //console.logString("Sell quantity");
        //console.logUint(assetsOut1);
        uint256 assetsOut3 = liquidityBootstrapPoolTest.previewAssetsOut(userShares1);

        console.logUint(assetsOut3);

        // Sell shares
        liquidityBootstrapPoolTest.swapExactSharesForAssets(userShares1, assetsOut3, initialOwner);

        uint256 userShares2 = liquidityBootstrapPoolTest.purchasedShares(initialOwner);
        //console.logString("Amount after sale");
        console.logUint(userShares2);

        vm.warp(block.timestamp + 43300);

        console.logString("==================4");

        // Buy shares
        liquidityBootstrapPoolTest.swapExactAssetsForShares(
            liquidityBootstrapPoolTest.previewAssetsIn(10 ether),
            0,
            initialOwner
        );

        console.logUint(liquidityBootstrapPoolTest.purchasedShares(initialOwner));

        vm.warp(block.timestamp + 96400);
        console.logString("==================5");

        liquidityBootstrapPoolTest.close();
        console.logString("==================6");
        console.logUint(liquidityBootstrapPoolTest.totalSwapFeesAsset());
        console.logUint(liquidityBootstrapPoolTest.totalSwapFeesShare());
        console.logUint(liquidityBootstrapPoolTest.referredAssets(initialOwner));

        console.logUint(liquidityBootstrapPoolTest.purchasedShares(initialOwner));

        liquidityBootstrapPoolTest.redeem(initialOwner, false);

        console.logUint(testToken1.balanceOf(address(liquidityBootstrapPoolTest)));
        console.logUint(testToken2.balanceOf(address(liquidityBootstrapPoolTest)));
        // vm.stopPrank();

        liquidityBootstrapPoolTest.emergencyWithdrawal(initialOwner);
        console.logUint(testToken2.balanceOf(address(liquidityBootstrapPoolTest)));
    }
}
