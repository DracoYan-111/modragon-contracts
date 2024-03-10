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
}
