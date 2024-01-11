// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import {MoBoxTokenBurn} from "../../src/moBoxBurn/MoBoxTokenBurn.sol";
import {TestToken} from "./testToken/TestToken.sol";

contract MoBoxTokenBurnTest is Test {
    TestToken public testToken;
    MoBoxTokenBurn public moBoxTokenBurnTest;

    address public initialOwner;
    IERC20 public moboxTokenAddressl;

    uint256 public constant BURN_AMOUNT = 0.1 ether;
    uint256 public constant INITIALOWNERKEY = 0xde9be858da4a475276426320d5e9262ecfc3ba460bfac56360bfa6c4c28b4ee0;

    /**
     * @dev Sets up the test.
     */
    function setUp() external {
        initialOwner = vm.addr(INITIALOWNERKEY);

        testToken = new TestToken(initialOwner);
        moBoxTokenBurnTest = new MoBoxTokenBurn(BURN_AMOUNT, initialOwner, testToken);
    }

    function testOwnerEq() external {
        assertEq(moBoxTokenBurnTest.owner(), initialOwner);
    }

    function testBurnAmountEq() external {
        assertEq(moBoxTokenBurnTest.burnAmount(), BURN_AMOUNT);
    }

    function testSetBurnAmount() external {
        vm.prank(initialOwner);
        moBoxTokenBurnTest.updateBurnAmount(0.2 ether);
        assertEq(moBoxTokenBurnTest.burnAmount(), 0.2 ether);
    }

    function testPause() external {
        vm.prank(initialOwner);
        moBoxTokenBurnTest.pause();
        vm.prank(initialOwner);
        moBoxTokenBurnTest.unpause();
    }

    function testBurnTokenForPowern() public {
        mintAndApproveToken();

        moBoxTokenBurnTest.burnTokenForPower(1);
    }

    function testFail_UserBurnTokenCountEq0() external {
        mintAndApproveToken();

        moBoxTokenBurnTest.burnTokenForPower(0);
    }

    function testFail_UserBurnTokenCountEq10() external {
        mintAndApproveToken();

        moBoxTokenBurnTest.burnTokenForPower(10);
    }

    function mintAndApproveToken() private {
        vm.prank(initialOwner);
        testToken.mint(address(this), 999999 ether);

        testToken.approve(address(moBoxTokenBurnTest), 999999 ether);
    }
}
