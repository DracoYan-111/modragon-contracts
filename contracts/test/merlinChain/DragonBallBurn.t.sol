// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {TestNFT} from "../testToken/TestNFT.sol";
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

        testNFT = new TestNFT(initialOwner);

        address proxy = Upgrades.deployUUPSProxy(
            "DragonBallBurn.sol",
            abi.encodeCall(MyContract.initialize, (initialOwner, testNFT, 1))
        );

        dragonBallBurn = DragonBallBurn(proxy);

        assertEq(dragonBallBurn.owner(), initialOwner);
    }
}
