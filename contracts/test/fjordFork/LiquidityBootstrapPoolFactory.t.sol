// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";


import {LiquidityBootstrapPool, FixedPointMathLib, WeightedMathLib} from "../../src/fjordFork/LiquidityBootstrapPoolNew.sol";
import {LiquidityBootstrapPoolFactory, PoolSettings} from "../../src/fjordFork/LiquidityBootstrapPoolFactory.sol";
import {LiquidityBootstrapLib, Pool} from "../../src/fjordFork/utils/LiquidityBootstrapLib.sol";
import {TestToken} from "../../src/testToken/TestToken.sol";

contract LiquidityBootstrapPoolFactoryTest is Test {
    using LiquidityBootstrapLib for *;
    using FixedPointMathLib for *;
    using WeightedMathLib for *;

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

    /**
     * @dev Test factory contract CreateLiquidityBootstrapPool function
     */
    function testCreateLiquidityBootstrapPool() public {
        vm.startPrank(initialOwner, initialOwner);
        testToken1.mint(initialOwner, 100000 ether);
        testToken1.approve(address(liquidityBootstrapPoolFactoryTest), 100000 ether);

        testToken2.mint(initialOwner, 100000 ether);
        testToken2.approve(address(liquidityBootstrapPoolFactoryTest), 100000 ether);

        PoolSettings memory poolSettings = PoolSettings(
            address(testToken1), // A token
            address(testToken2), // B token
            initialOwner, // manger
            0, // default
            0, // default
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
    }

    /**
     * @dev Test pool contract buy function
     */
    function testPoolContractBuy() public {
        testCreateLiquidityBootstrapPool();

        assertGt(liquidityBootstrapPoolTest.previewAssetsIn(10 ether), 0);

        vm.warp(block.timestamp + 1000);

        uint256 assetsIn = liquidityBootstrapPoolTest.previewAssetsIn(10 ether);
        // Buy 10ether assets need
        assertGt(assetsIn, 0);

        uint256 sharesIn = liquidityBootstrapPoolTest.previewSharesIn(assetsIn);
        assertGt(sharesIn, 0);

        uint256 assetsOut = liquidityBootstrapPoolTest.previewAssetsOut(10 ether);
        assertGt(assetsOut, 0);

        uint256 sharesOut = liquidityBootstrapPoolTest.previewSharesOut(assetsOut);
        assertGt(sharesOut, 0);

        //===========================================================================

        vm.warp(block.timestamp + 2000);

        // Buy shares
        liquidityBootstrapPoolTest.swapExactAssetsForShares(assetsIn, sharesOut, initialOwner);

        uint256 userShares = liquidityBootstrapPoolTest.purchasedShares(initialOwner);
        // Amount after purchase
        assertGt(userShares, 0);

        assertEq(liquidityBootstrapPoolTest.totalSwapFeesAsset(), 0);

        vm.warp(block.timestamp + 3000);
    }

    /**
     * @dev Test pool contract sell function
     */
    function testPoolContractSell() public {
        testPoolContractBuy();

        uint256 userShares = liquidityBootstrapPoolTest.purchasedShares(initialOwner);
        assertGt(userShares, 0);

        uint256 assetsOut = liquidityBootstrapPoolTest.previewAssetsOut(userShares);
        assertGt(assetsOut, 0);

        // Sell shares
        liquidityBootstrapPoolTest.swapExactSharesForAssets(userShares, assetsOut, initialOwner);

        uint256 userSharesNew = liquidityBootstrapPoolTest.purchasedShares(initialOwner);
        assertEq(userSharesNew, 0);

        assertEq(liquidityBootstrapPoolTest.totalSwapFeesAsset(), 0);

        vm.warp(block.timestamp + 43300);
    }

    /**
     * @dev Test pool contract close function
     */
    function testPoolContractClose() public {
        testPoolContractSell();

        vm.warp(block.timestamp + 96400);

        liquidityBootstrapPoolTest.close();

        assertEq(liquidityBootstrapPoolTest.closed(), true);
        assertEq(liquidityBootstrapPoolTest.totalSwapFeesAsset(), 0);
    }

    /**
     * @dev Test pool contract redeem function
     */
    function testPoolContractRedeem() public {
        testPoolContractBuy();
        vm.warp(block.timestamp + 96400);

        liquidityBootstrapPoolTest.close();

        uint256 userShares = liquidityBootstrapPoolTest.purchasedShares(initialOwner);
        assertGt(userShares, 0);
    }
}
