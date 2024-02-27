// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {TestToken} from "../../src/testToken/TestToken.sol";
import {DragonBallHatch} from "../../src/merlinChain/DragonBallHatch.sol";

contract DragonBallBurnTest is Test {
    TestToken public testToken;
    DragonBallHatch public dragonBallHatch;

    address public initialOwner;
    uint256 public constant INITIALOWNERKEY = 0xde9be858da4a475276426320d5e9262ecfc3ba460bfac56360bfa6c4c28b4ee0;

    /**
     * @dev Sets up the test.
     */
    function setUp() external {
        initialOwner = vm.addr(INITIALOWNERKEY);

        testToken = new TestToken(initialOwner);

        address dragonBallHatchs = address(new DragonBallHatch());

        bytes memory data = abi.encodeCall(DragonBallHatch.initialize, (initialOwner));
        address proxy = address(new ERC1967Proxy(dragonBallHatchs, data));

        dragonBallHatch = DragonBallHatch(proxy);
    }

    function testGetOwner() public {
        assertEq(dragonBallHatch.owner(), initialOwner);
    }

    function testPauseAndUnpause() external {
        vm.startPrank(initialOwner, initialOwner);

        dragonBallHatch.pause();
        dragonBallHatch.unpause();
    }

    function testFail_PauseAndUnpauseNotOwner() external {
        dragonBallHatch.pause();
        dragonBallHatch.unpause();
    }

    function testHatchBallsERC20() external {
        vm.startPrank(initialOwner, initialOwner);

        testToken.mint(initialOwner, 10 ether);
        testToken.approve(address(dragonBallHatch), 10 ether);

        dragonBallHatch.hatchBalls("123123abcabc", testToken, 1 ether);
    }

    function testFail_HatchBallsNotApprove() external {
        vm.startPrank(initialOwner, initialOwner);

        testToken.mint(initialOwner, 10 ether);

        dragonBallHatch.hatchBalls("123123abcabc", testToken, 1 ether);
    }

    function testHatchBallsGasToken() external {
        vm.startPrank(initialOwner, initialOwner);

        dragonBallHatch.hatchBalls{value: 1 ether}("123123abcabc", IERC20(address(0)), 1 ether);
    }

    function testFail_HatchBallsMistakeValueAmount() external {
        vm.startPrank(initialOwner, initialOwner);

        dragonBallHatch.hatchBalls{value: 10 ether}("123123abcabc", IERC20(address(0)), 1 ether);
    }
}
