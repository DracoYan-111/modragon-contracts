// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23.0;

import {DrawnBringerNFT} from "../../src/drawnBringer/DrawnBringerNFT.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";


contract DrawnBringerNFTTest is Test{
    string public constant TOKNE_URI = "token uri";
    string public constant NEW_TOKNE_URI = "new token uri";
    address public initialOwner;


    DrawnBringerNFT public moDragonContractTest;

    /**
     * @dev Sets up the test.
     */
    function setUp() external {
        initialOwner = msg.sender;

        moDragonContractTest = new DrawnBringerNFT(
            TOKNE_URI,
            initialOwner,
            msg.sender
        );
    }
    
    function test_Owner_Eq() external {
        assertEq(moDragonContractTest.owner(), initialOwner);
    }

    function test_TokenURI_Eq() external {
        assertEq(moDragonContractTest.tokenURI(0), TOKNE_URI);
    }

}
