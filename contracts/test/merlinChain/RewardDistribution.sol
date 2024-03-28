// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {TestNFT, IERC721} from "../../src/testToken/TestNFT.sol";

import {RewardDistribution} from "../../src/merlinChain/RewardDistribution.sol";

contract RewardDistributionTest is Test {
    TestNFT public testNFT;
    RewardDistribution public rewardDistribution;

    address public initialOwner;
    uint256 public constant INITIALOWNERKEY = 0xde9be858da4a475276426320d5e9262ecfc3ba460bfac56360bfa6c4c28b4ee0;

    /**
     * @dev Sets up the test.
     */
    function setUp() external {
        initialOwner = vm.addr(INITIALOWNERKEY);

        testNFT = new TestNFT(initialOwner, "TestNFT");

        address rewardDistributions = address(new RewardDistribution());

        bytes memory data = abi.encodeCall(
            RewardDistribution.initialize,
            (initialOwner, testNFT, testNFT, 0xaa78a00191152ba8b1e0ebe5831950ff7ec12b295c38c26aeaceced2e4478cb8)
        );
        address proxy = address(new ERC1967Proxy(rewardDistributions, data));

        rewardDistribution = RewardDistribution(proxy);
    }

    function testGetOwnerAndPendingOwner() public {
        assertEq(rewardDistribution.owner(), initialOwner);
        assertEq(rewardDistribution.pendingOwner(), address(0));
    }

    function testPauseAndUnpause() external {
        vm.startPrank(initialOwner, initialOwner);

        rewardDistribution.pause();
        rewardDistribution.unpause();
    }

    function testFail_PauseAndUnpauseNotOwner() external {
        rewardDistribution.pause();
        rewardDistribution.unpause();
    }

    function testClaim() public {
        vm.startPrank(initialOwner, initialOwner);

        for (uint256 i; i < 10; ++i) {
            testNFT.safeMint(address(rewardDistribution));
        }

        vm.startPrank(0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 0x70997970C51812dc3A010C7d01b50e0d17dc79C8);

        uint256[] memory tokenIDs = new uint256[](4);
        tokenIDs[0] = 1;
        tokenIDs[1] = 2;
        tokenIDs[2] = 3;
        tokenIDs[3] = 4;
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = 0x17e170678287a9644a243e899337b495d40729a7a0f0d66b7fb297843c24968b;
        proof[1] = 0x82b925d1fd548cda7094be410987c1474937d0781df40346b722978b9df8e563;

        rewardDistribution.claim(0, tokenIDs, tokenIDs, proof);
        assertEq(rewardDistribution.isClaimed(0), true);
    }
}
