// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {DrawnBringerNFT} from "../../src/drawnBringer/DrawnBringerNFT.sol";
import {Test} from "forge-std/Test.sol";

contract DrawnBringerNFTTest is Test {
    DrawnBringerNFT public moDragonContractTest;

    /**
     * @dev Sets up the test.
     */
    function setUp() public {
        moDragonContractTest = new DrawnBringerNFT(
            "tokenUri=============",
            msg.sender, 
            msg.sender
        );
    
    }
}
