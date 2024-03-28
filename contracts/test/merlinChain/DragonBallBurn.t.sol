// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {TestNFT} from "../../src/testToken/TestNFT.sol";
import {DragonBallBurn} from "../../src/merlinChain/DragonBallBurn.sol";

contract DragonBallBurnTest is Test {
    TestNFT public testNFT;
    DragonBallBurn public dragonBallBurn;

    address public initialOwner;
    uint256 public constant INITIALOWNERKEY = 0xde9be858da4a475276426320d5e9262ecfc3ba460bfac56360bfa6c4c28b4ee0;

    /**
     * @dev Sets up the test.
     */
    function setUp() external {
        initialOwner = vm.addr(INITIALOWNERKEY);

        testNFT = new TestNFT(initialOwner,"TestNFT");

        address dragonBallBurns = address(new DragonBallBurn());

        bytes memory data = abi.encodeCall(DragonBallBurn.initialize, (initialOwner, testNFT, 31337));
        address proxy = address(new ERC1967Proxy(dragonBallBurns, data));

        dragonBallBurn = DragonBallBurn(proxy);
    }

    function testGetOwner() public {
        assertEq(dragonBallBurn.owner(), initialOwner);
    }

    function testPauseAndUnpause() external {
        vm.startPrank(initialOwner, initialOwner);

        dragonBallBurn.pause();
        dragonBallBurn.unpause();
    }

    function testFail_PauseAndUnpauseNotOwner() external {
        dragonBallBurn.pause();
        dragonBallBurn.unpause();
    }

    function testUpdateBurnNFTAddress() external {
        vm.startPrank(initialOwner, initialOwner);

        dragonBallBurn.updateBurnNFTAddress(testNFT);
    }

    function testFail_UpdateBurnNFTAddressNotOwner() external {
        dragonBallBurn.updateBurnNFTAddress(testNFT);
    }

    function testUpdateCheckChainId() external {
        vm.startPrank(initialOwner, initialOwner);

        dragonBallBurn.updateCheckChainId(1);
    }

    function testFail_UpdateCheckChainIdNotOwner() external {
        dragonBallBurn.updateCheckChainId(1);
    }

    function testBurnNfGetCoupons() external {
        vm.startPrank(initialOwner, initialOwner);

        uint256[] memory testIds = new uint256[](10);
        for (uint256 i; i < 10; ) {
            testNFT.safeMint(initialOwner);
            testIds[i] = i;
            unchecked {
                ++i;
            }
        }

        testNFT.setApprovalForAll(address(dragonBallBurn), true);

        dragonBallBurn.burnNftGetCoupons(testIds, initialOwner);

        assertEq(testNFT.balanceOf(address(dragonBallBurn)), 10);
    }

    function testFail_BurnNfGetCouponsNotApproval() external {
        vm.startPrank(initialOwner, initialOwner);

        uint256[] memory testIds = new uint256[](10);
        for (uint256 i; i < 10; ) {
            testNFT.safeMint(initialOwner);
            testIds[i] = i;
            unchecked {
                ++i;
            }
        }

        dragonBallBurn.burnNftGetCoupons(testIds, initialOwner);
    }

    function testFail_BurnNfGetCouponsNotTargetAddress() external {
        vm.startPrank(initialOwner, initialOwner);

        uint256[] memory testIds = new uint256[](10);
        for (uint256 i; i < 10; ) {
            testNFT.safeMint(initialOwner);
            testIds[i] = i;
            unchecked {
                ++i;
            }
        }

        testNFT.setApprovalForAll(address(dragonBallBurn), true);

        dragonBallBurn.burnNftGetCoupons(testIds, address(0));
    }

    function testWithdrawNfts() external {
        this.testBurnNfGetCoupons();

        uint256[] memory testIds = new uint256[](3);
        testIds[0] = 1;
        testIds[1] = 2;
        testIds[2] = 3;

        assertEq(testNFT.balanceOf(address(dragonBallBurn)), 10);

        dragonBallBurn.withdrawNfts(testIds, initialOwner);

        assertEq(testNFT.balanceOf(address(dragonBallBurn)), 7);
    }

    function testWithdrawNftsGetBurnNftIds() external {
        this.testBurnNfGetCoupons();

        uint256[] memory testIds = new uint256[](10);
        for (uint256 i; i < 10; ) {
            testIds[i] = i;
            unchecked {
                ++i;
            }
        }

        assertEq(testNFT.balanceOf(address(dragonBallBurn)), 10);

        dragonBallBurn.withdrawNfts(testIds, initialOwner);

        assertEq(dragonBallBurn.getBurnNftIds(), testIds);
    }

    function testWithdrawNftsGetWithdrawBurnNftIds() external {
        this.testBurnNfGetCoupons();

        uint256[] memory testIds = new uint256[](3);
        for (uint256 i; i < 3; ) {
            testIds[i] = i;
            unchecked {
                ++i;
            }
        }

        assertEq(testNFT.balanceOf(address(dragonBallBurn)), 10);

        dragonBallBurn.withdrawNfts(testIds, initialOwner);

        assertEq(dragonBallBurn.getWithdrawBurnNftIds(), testIds);
    }

    function testFail_WithdrawNftsNotOwner() external {
        this.testBurnNfGetCoupons();

        vm.stopPrank();

        uint256[] memory testIds = new uint256[](3);
        testIds[0] = 1;
        testIds[1] = 2;
        testIds[2] = 3;

        assertEq(testNFT.balanceOf(address(dragonBallBurn)), 10);

        dragonBallBurn.withdrawNfts(testIds, initialOwner);
    }

    function testFail_WithdrawNftsWrongTokenId() external {
        this.testBurnNfGetCoupons();

        uint256[] memory testIds = new uint256[](3);
        testIds[0] = 1;
        testIds[1] = 2;
        testIds[2] = 30;

        assertEq(testNFT.balanceOf(address(dragonBallBurn)), 10);

        dragonBallBurn.withdrawNfts(testIds, initialOwner);
    }
}
