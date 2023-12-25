// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {MoDragonContract} from "../../src/modragon/MoDragonContract.sol";
import {Test} from "forge-std/Test.sol";

contract MoDragonContractTest is Test {
    MoDragonContractTest moDragonContractTest;

    /**
     * @dev Sets up the test.
     */
    function setUp() public {
        moDragonContractTest = new MoDragonContractTest(
            "123123123",
            msg.sender,
            msg.sender
        );
    }
}
