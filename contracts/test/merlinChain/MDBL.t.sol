// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {MDBL} from "../../src/merlinChain/MDBL.sol";

contract MDBLTest is Test {
    MDBL public testMDBL;

    address public initialOwner;
    uint256 public constant INITIALOWNERKEY = 0xde9be858da4a475276426320d5e9262ecfc3ba460bfac56360bfa6c4c28b4ee0;

    /**
     * @dev Sets up the test.
     */
    function setUp() external {
        initialOwner = vm.addr(INITIALOWNERKEY);

        address dragonBallBurns = address(new MDBL());

        bytes memory data = abi.encodeCall(MDBL.initialize, (initialOwner));
        address proxy = address(new ERC1967Proxy(dragonBallBurns, data));

        testMDBL = MDBL(proxy);
    }

    function testGetOwnerAndPendingOwner() public {
        assertEq(testMDBL.owner(), initialOwner);
        assertEq(testMDBL.pendingOwner(), address(0));
    }

    function testPauseAndUnpause() external {
        vm.startPrank(initialOwner, initialOwner);

        testMDBL.pause();
        testMDBL.unpause();
    }

    function testFail_PauseAndUnpauseNotOwner() external {
        testMDBL.pause();
        testMDBL.unpause();
    }

    function testTransferOwnership() external {
        vm.startPrank(initialOwner, initialOwner);

        testMDBL.transferOwnership(initialOwner);
        assertEq(testMDBL.pendingOwner(), initialOwner);

        testMDBL.acceptOwnership();
        assertEq(testMDBL.pendingOwner(), address(0));
    }

    function testFail_TransferOwnershipNotOwner() external {
        testMDBL.transferOwnership(initialOwner);
    }

    function testFail_TransferOwnershipNotPendingOwner() external {
        vm.startPrank(initialOwner, initialOwner);

        testMDBL.transferOwnership(initialOwner);
        assertEq(testMDBL.pendingOwner(), initialOwner);

        vm.stopPrank();

        testMDBL.acceptOwnership();
    }

    function testMint() public {
        vm.startPrank(initialOwner, initialOwner);

        testMDBL.mint(initialOwner, 10000 ether);
        assertEq(testMDBL.balanceOf(initialOwner), 10000 ether);
    }

    function testFail_MintNotOwner() external {
        testMDBL.mint(initialOwner, 10000 ether);
    }

    function testBurn() external {
        testMint();

        testMDBL.burn(1 ether);
        assertEq(testMDBL.balanceOf(initialOwner), 9999 ether);
        assertEq(testMDBL.totalSupply(), 9999 ether);
    }

    function testBurnFrom() external {
        testMint();

        testMDBL.approve(address(this), 1 ether);
        vm.stopPrank();

        testMDBL.burnFrom(initialOwner, 1 ether);

        assertEq(testMDBL.balanceOf(initialOwner), 9999 ether);
        assertEq(testMDBL.totalSupply(), 9999 ether);
    }
}
