// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {TestNFT} from "../../src/testToken/TestNFT.sol";
import {BatchBurnERC721} from "../../src/merlinChain/BatchBurnERC721.sol";

contract BatchBurnERC721Test is Test {
    TestNFT public testNFT;
    BatchBurnERC721 public batchBurnERC721;

    address public initialOwner;
    uint256 public constant INITIALOWNERKEY = 0xde9be858da4a475276426320d5e9262ecfc3ba460bfac56360bfa6c4c28b4ee0;

    /**
     * @dev Sets up the test.
     */
    function setUp() external {
        initialOwner = vm.addr(INITIALOWNERKEY);

        testNFT = new TestNFT(initialOwner, "TestNFT");

        address batchBurnERC721s = address(new BatchBurnERC721());

        bytes memory data = abi.encodeCall(BatchBurnERC721.initialize, (initialOwner, testNFT));
        address proxy = address(new ERC1967Proxy(batchBurnERC721s, data));

        batchBurnERC721 = BatchBurnERC721(proxy);
    }

    function testFail_batchBurnNotToken() public {
        vm.startPrank(initialOwner, initialOwner);

        uint256[] memory tokenIdList = new uint256[](4);

        tokenIdList[0] = 0;
        tokenIdList[1] = 1;
        tokenIdList[2] = 2;
        tokenIdList[3] = 3;

        batchBurnERC721.batchBurn(tokenIdList);
    }

    function testBatchBurn() public {
        vm.startPrank(initialOwner, initialOwner);

        testNFT.batchSafeMint(initialOwner, 4);
        assertEq(testNFT.balanceOf(initialOwner), 4);

        testNFT.setApprovalForAll(address(batchBurnERC721), true);
        
        uint256[] memory tokenIdList = new uint256[](4);
        tokenIdList[0] = 0;
        tokenIdList[1] = 1;
        tokenIdList[2] = 2;
        tokenIdList[3] = 3;

        batchBurnERC721.batchBurn(tokenIdList);

        assertEq(testNFT.balanceOf(initialOwner), 0);
    }
}

//forge test -vvv --root . -C contracts/src --match-path contracts/test/merlinChain/BatchBurnERC721.t.sol --out forge-artifacts
