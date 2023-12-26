// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {MoDragonContract} from "../../src/modragon/MoDragonContract.sol";
import {Test} from "forge-std/Test.sol";

contract MoDragonContractTest is Test {
    MoDragonContract public moDragonContractTest;

    /**
     * @dev Sets up the test.
     */
    function setUp() public {
        moDragonContractTest = new MoDragonContract(
            "tokenUri=============",
            msg.sender, 
            msg.sender
        );
    
    }
}
