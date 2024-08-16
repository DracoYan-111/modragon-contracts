// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import {TestToken, IERC20} from "../../src/testToken/TestToken.sol";
import {RankTokenDistribution} from "../../src/merlinChain/RankTokenDistribution.sol";

contract RankTokenDistributionTest is Test {
    TestToken public testToken;
    RankTokenDistribution public rankTokenDistribution;

    address public initialOwner;
    uint256 public constant INITIALOWNERKEY = 0xde9be858da4a475276426320d5e9262ecfc3ba460bfac56360bfa6c4c28b4ee0;

    struct UserData {
        uint256 index;
        uint256 amount;
        bytes32[] merkleProof;
    }

    /**
     * @dev Sets up the test.
     */
    function setUp() external {
        initialOwner = vm.addr(INITIALOWNERKEY);

        testToken = new TestToken(initialOwner, "TestToken");

        address rankTokenDistributionDef = address(new RankTokenDistribution());
        bytes memory dataOne = abi.encodeCall(RankTokenDistribution.initialize, initialOwner);
        address proxyRankTokenDistribution = address(new ERC1967Proxy(rankTokenDistributionDef, dataOne));
        rankTokenDistribution = RankTokenDistribution(proxyRankTokenDistribution);
    }

    function getMerkleProof() public pure returns (UserData memory) {
        bytes32[] memory merkleProof = new bytes32[](8);

        merkleProof[0] = 0x3ee6ce33185141ea97f89c08ea2ca7cb7814d4390063026f6faf1170c2c6f02b;
        merkleProof[1] = 0xee9325045b2ddea29a63ad14373b8e1454eee7c001c1c6f8432858a1367c80d2;
        merkleProof[2] = 0xdae83558b0c0fd35944e18c78efbf184788eaeaa4e1352b90fa6300334cb1b9f;
        merkleProof[3] = 0xa8e3d0495b458d977a3a216e65621e72fc803f61378c8015da32c6accada1a84;
        merkleProof[4] = 0xdaecd716fb9abd1e93abf626d4b116729845e52f9c208aa713fd82eff2737ce2;
        merkleProof[5] = 0x307ca5bdc5903f63feae602787742a1ceea3742acf3e50d711e360b326b3a1bf;
        merkleProof[6] = 0xdf1760604b0e8beb13317f6f69eb55fbdbab3c1e2ee35281597ac78c449385ee;
        merkleProof[7] = 0x41cf5717ce8ddbbf52a1d0293350f61fcf329204a6f352d742e86db506b7c391;

        UserData memory userData;
        userData.index = 185;
        userData.amount = 2000000000000000000;
        userData.merkleProof = merkleProof;

        return userData;
    }

    function testFail_usersReceiveTokenRewardsNotTokenBalance() public {
        vm.startPrank(initialOwner, initialOwner);

        rankTokenDistribution.setSeasonData(
            0,
            IERC20(testToken),
            0x86b9d28ba37381d3d174e8d28e6b560e44f3a2019f74e18a31bce88eb516e66c
        );
        UserData memory userData = getMerkleProof();
        rankTokenDistribution.usersReceiveTokenRewards(userData.index, userData.amount, userData.merkleProof);
    }

    function testFail_usersReceiveTokenRewardsNotSetSeasonReceiveRoot() public {
        vm.startPrank(initialOwner, initialOwner);

        testToken.mint(address(rankTokenDistribution), 10000 ether);

        UserData memory userData = getMerkleProof();
        rankTokenDistribution.usersReceiveTokenRewards(userData.index, userData.amount, userData.merkleProof);
    }

    function testusersReceiveTokenRewards() public {
        vm.startPrank(initialOwner, initialOwner);

        rankTokenDistribution.setSeasonData(
            0,
            IERC20(testToken),
            0x86b9d28ba37381d3d174e8d28e6b560e44f3a2019f74e18a31bce88eb516e66c
        );

        testToken.mint(address(rankTokenDistribution), 10000 ether);

        UserData memory userData = getMerkleProof();
        rankTokenDistribution.usersReceiveTokenRewards(userData.index, userData.amount, userData.merkleProof);

        assertEq(rankTokenDistribution.getUserRewardsReceived(0, initialOwner), userData.amount);
    }
}
//forge test -vvv --root . -C contracts/src --match-path contracts/test/merlinChain/RankTokenDistribution.t.sol --out forge-artifacts
