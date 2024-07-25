// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import {IERC20, TestToken} from "../../src/testToken/TestToken.sol";

import {MERLRewardDistribution} from "../../src/mdblLBP/mdblStake/MERLRewardDistribution.sol";

contract MERLRewardDistributionTest is Test {
    bytes32 public constant PERMIT_TRANSFERHASH =
        keccak256("PermitTransfer(address to,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant domainSeparator = 0xd2b1de47282de02dc18779282400bad8102514c9364599a0882e475043c8393a;

    uint256 public constant INITIALOWNERKEY = 0xde9be858da4a475276426320d5e9262ecfc3ba460bfac56360bfa6c4c28b4ee0;
    uint256 public constant SIGNERPRIVATEKEY = 0xe122d806c802056221f3f52d477fa40a45dae4264c515e5949a51a92d7e2c022;

    TestToken public testMDBL;
    address public initialOwner;
    address public signerAddress;

    MERLRewardDistribution public mERLRewardDistributionTest;

    /**
     * @dev Sets up the test.
     */
    function setUp() external {
        initialOwner = vm.addr(INITIALOWNERKEY);
        signerAddress = vm.addr(SIGNERPRIVATEKEY);

        testMDBL = new TestToken(initialOwner, "TestToken");

        address mERLRewardDistribution = address(new MERLRewardDistribution());
        bytes memory data = abi.encodeCall(
            MERLRewardDistribution.initialize,
            (initialOwner, testMDBL, vm.addr(SIGNERPRIVATEKEY))
        );
        address proxyLeaderboardReward = address(new ERC1967Proxy(mERLRewardDistribution, data));
        mERLRewardDistributionTest = MERLRewardDistribution(proxyLeaderboardReward);
    }

    function testPermitTransfer() external {
        vm.startPrank(initialOwner, initialOwner);

        testMDBL.mint(address(mERLRewardDistributionTest), 100000 ether);

        uint256 deadline = 2705755809;

        bytes32 typedDataHash = getTypedDataHash(deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNERPRIVATEKEY, typedDataHash);

        mERLRewardDistributionTest.permitTransfer(initialOwner, 100 ether, deadline, v, r, s);

        assertEq(testMDBL.balanceOf(initialOwner), 100 ether);
    }

    function getTypedDataHash(uint256 deadline) private view returns (bytes32 typedDataHash) {
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TRANSFERHASH,
                initialOwner,
                100 ether,
                mERLRewardDistributionTest.nonces(initialOwner),
                deadline
            )
        );

        typedDataHash = MessageHashUtils.toTypedDataHash(mERLRewardDistributionTest.DOMAIN_SEPARATOR(), structHash);
    }
}
