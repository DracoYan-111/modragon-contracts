// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import {TestToken} from "../../src/testToken/TestToken.sol";
import {eMDBL, IERC20} from "../../src/mdblLBP/mdblStake/eMDBL.sol";
import {LeaderboardRewards} from "../../src/merlinChain/LeaderboardRewards.sol";

contract LeaderboardRewardsTest is Test {
    TestToken public testMDBL;
    eMDBL public testeMDBL;
    LeaderboardRewards public leaderboardRewards;

    address public initialOwner;
    uint256 public constant INITIALOWNERKEY = 0xde9be858da4a475276426320d5e9262ecfc3ba460bfac56360bfa6c4c28b4ee0;
    uint256 public constant SIGNERPRIVATEKEY = 0xdf57089febbacf7ba0bc227dafbffa9fc08a93fdc68e1e42411a14efcf23656e;
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("PermitClaim(address tokenAddress,address to,uint256 amount,uint256 nonce,uint256 deadline)");

    /**
     * @dev Sets up the test.
     */
    function setUp() external {
        initialOwner = vm.addr(INITIALOWNERKEY);

        testMDBL = new TestToken(initialOwner, "TestToken");

        address eMDBLtoken = address(new eMDBL());
        bytes memory data = abi.encodeCall(
            eMDBL.initialize,
            (initialOwner, initialOwner, IERC20(testMDBL), vm.addr(SIGNERPRIVATEKEY))
        );
        address proxyeMDBL = address(new ERC1967Proxy(eMDBLtoken, data));
        testeMDBL = eMDBL(proxyeMDBL);

        address leaderboardReward = address(new LeaderboardRewards());
        bytes memory dataOne = abi.encodeCall(
            LeaderboardRewards.initialize,
            (initialOwner, vm.addr(SIGNERPRIVATEKEY), address(testMDBL), address(testeMDBL))
        );
        address proxyLeaderboardReward = address(new ERC1967Proxy(leaderboardReward, dataOne));
        leaderboardRewards = LeaderboardRewards(proxyLeaderboardReward);
    }

    function testFail_PermitClaimNotRole() public {
        vm.startPrank(initialOwner, initialOwner);

        uint256 amount = 10 ether;
        uint256 deadline = 1 ether;
        bytes32 typedDataHash = getTypedDataHash(deadline, initialOwner, amount, address(testeMDBL));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNERPRIVATEKEY, typedDataHash);
        leaderboardRewards.permitClaim(address(testeMDBL), initialOwner, amount, deadline, v, r, s);
    }

    function testFail_PermitClaimSingerErr() public {
        vm.startPrank(initialOwner, initialOwner);

        uint256 amount = 10 ether;
        uint256 deadline = 1 ether;
        bytes32 typedDataHash = getTypedDataHash(deadline, initialOwner, amount, address(testeMDBL));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(INITIALOWNERKEY, typedDataHash);
        leaderboardRewards.permitClaim(address(testeMDBL), initialOwner, amount, deadline, v, r, s);
    }

    function testPermitClaim() public {
        vm.startPrank(initialOwner, initialOwner);

        testeMDBL.grantRole(keccak256("MINTER_ROLE"), address(leaderboardRewards));

        uint256 amount = 10 ether;
        uint256 deadline = 1 ether;
        bytes32 typedDataHash = getTypedDataHash(deadline, initialOwner, amount, address(testeMDBL));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNERPRIVATEKEY, typedDataHash);
        leaderboardRewards.permitClaim(address(testeMDBL), initialOwner, amount, deadline, v, r, s);

        assertEq(testeMDBL.balanceOf(initialOwner), amount);
    }

    function testFail_PermitClaimMDBLBalance() public {
        vm.startPrank(initialOwner, initialOwner);

        uint256 amount = 10 ether;
        uint256 deadline = 1 ether;
        bytes32 typedDataHash = getTypedDataHash(deadline, initialOwner, amount, address(testMDBL));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(INITIALOWNERKEY, typedDataHash);
        leaderboardRewards.permitClaim(address(testeMDBL), initialOwner, amount, deadline, v, r, s);
    }

    function testPermitClaimMDBL() public {
        vm.startPrank(initialOwner, initialOwner);

        testMDBL.mint(address(leaderboardRewards), 1000 ether);

        uint256 amount = 10 ether;
        uint256 deadline = 1 ether;
        bytes32 typedDataHash = getTypedDataHash(deadline, initialOwner, amount, address(testMDBL));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNERPRIVATEKEY, typedDataHash);
        leaderboardRewards.permitClaim(address(testMDBL), initialOwner, amount, deadline, v, r, s);

        assertEq(testMDBL.balanceOf(initialOwner), amount);
    }

    function getTypedDataHash(
        uint256 deadline,
        address to,
        uint256 amount,
        address tokenAddr
    ) private view returns (bytes32 typedDataHash) {
        bytes32 structHash = keccak256(
            abi.encode(PERMIT_TYPEHASH, tokenAddr, to, amount, leaderboardRewards.nonces(to), deadline)
        );

        typedDataHash = MessageHashUtils.toTypedDataHash(leaderboardRewards.DOMAIN_SEPARATOR(), structHash);
    }
}
