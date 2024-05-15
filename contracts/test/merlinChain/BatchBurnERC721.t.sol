// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {TestToken, IERC20} from "../../src/testToken/TestToken.sol";
import {TestNFT} from "../../src/testToken/TestNFT.sol";
import {eMDBL} from "../../src/mdblLBP/mdblStake/eMDBL.sol";
import {BatchBurnERC721} from "../../src/merlinChain/BatchBurnERC721.sol";

contract BatchBurnERC721Test is Test {
    TestNFT public testNFT;
    TestToken public testToken;
    eMDBL public eMDBLToken;
    BatchBurnERC721 public batchBurnERC721;

    address public initialOwner;
    uint256 public constant INITIALOWNERKEY = 0xde9be858da4a475276426320d5e9262ecfc3ba460bfac56360bfa6c4c28b4ee0;

    /**
     * @dev Sets up the test.
     */
    function setUp() external {
        initialOwner = vm.addr(INITIALOWNERKEY);

        testNFT = new TestNFT(initialOwner, "TestNFT");
        testToken = new TestToken(initialOwner, "TestToken");

        address eMDBLs = address(new eMDBL());
        bytes memory data1 = abi.encodeCall(
            eMDBL.initialize,
            (initialOwner, initialOwner, IERC20(initialOwner), initialOwner)
        );
        address proxy1 = address(new ERC1967Proxy(eMDBLs, data1));
        eMDBLToken = eMDBL(proxy1);

        address batchBurnERC721s = address(new BatchBurnERC721());
        bytes memory data = abi.encodeCall(BatchBurnERC721.initialize, (initialOwner, testNFT, 21000000 ether));
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

    function testFail_UsersReceiveeMDBLRewardsNotOpen() public {
        testBatchBurn();

        eMDBLToken.grantRole(eMDBLToken.MINTER_ROLE(), address(batchBurnERC721));

        batchBurnERC721.setTokenAddress(0, address(eMDBLToken));

        batchBurnERC721.usersReceiveeMDBLRewards();

        assertEq(eMDBLToken.balanceOf(initialOwner), 21000000 ether);
    }

    function testFail_UsersReceiveeMDBLRewardsNotRole() public {
        testBatchBurn();

        batchBurnERC721.setReceiveOpen();

        batchBurnERC721.setTokenAddress(0, address(eMDBLToken));

        batchBurnERC721.usersReceiveeMDBLRewards();

        assertEq(eMDBLToken.balanceOf(initialOwner), 21000000 ether);
    }

    function testFail_UsersReceiveeMDBLRewardsDone() public {
        testBatchBurn();

        eMDBLToken.grantRole(eMDBLToken.MINTER_ROLE(), address(batchBurnERC721));

        batchBurnERC721.setTokenAddress(0, address(eMDBLToken));
        batchBurnERC721.setReceiveOpen();

        batchBurnERC721.usersReceiveeMDBLRewards();

        batchBurnERC721.usersReceiveeMDBLRewards();
    }

    function testUsersReceiveeMDBLRewards() public {
        testBatchBurn();

        eMDBLToken.grantRole(eMDBLToken.MINTER_ROLE(), address(batchBurnERC721));

        batchBurnERC721.setTokenAddress(0, address(eMDBLToken));
        batchBurnERC721.setReceiveOpen();

        batchBurnERC721.usersReceiveeMDBLRewards();

        assertEq(eMDBLToken.balanceOf(initialOwner), 21000000 ether);
    }

    function testFail_UsersReceiveMERLRewardsNotSetTokenAddress() public {
        vm.startPrank(initialOwner, initialOwner);

        testToken.mint(address(batchBurnERC721), 10000000 ether);

        batchBurnERC721.setReceiveOpen();
        batchBurnERC721.setReceiveRoot(0xb0b5be6637cbb40bdf9d0528e1ab6100eed4b538f439e54d329c7cc85667f975);

        vm.startPrank(0x000D21da4B478B0406E5EAe9c61615Be5177Fa0B, 0x000D21da4B478B0406E5EAe9c61615Be5177Fa0B);

        bytes32[] memory rootList = new bytes32[](11);
        rootList[0] = bytes32(0xaa7a18f410d25884a48c3a2eac86383440896bbc61f87e06bbcf67dddbd15f86);
        rootList[1] = bytes32(0xa669c2c44fa87db3db0daadbf843a0d690e53f29e3733a85525edc931e24177a);
        rootList[2] = bytes32(0x45f6e8c99847b8131fd3998d132976883476fa9215d8f8feeca7f19ca13a4728);
        rootList[3] = bytes32(0x7f1d20029a45d43c29d4877159be0aa1a2f42b028142995a5b68c779a2e71a27);
        rootList[4] = bytes32(0x334323b897cabb7c9bbf377c4d1dcf5c3571fa053f06e3bb1a4e399c04fb126b);
        rootList[5] = bytes32(0x9aa38ebc7c41a74c41418fda86a2dcbacc94df119caa2086d895d3074468e7c0);
        rootList[6] = bytes32(0x05d84b3564394fdd1d97a46a1bdf0cfcfcf415d0ae58bc3cc35a0445dab773f7);
        rootList[7] = bytes32(0x1cc10da7ffc67dc3b1e62d896389911e84e5be0cefe574cf1ace5cb1414d234c);
        rootList[8] = bytes32(0x30fadabc57a81136f55f324503e3569538d9ba7f4750f27ad57c7901649d92d1);
        rootList[9] = bytes32(0x8a63a9d3be13ffc6f49175f562faa8e0680c06d96210b087d54dce78ce623201);
        rootList[10] = bytes32(0x8d57be6e031740c2062c538243791730562ce7f86adf3843416d867b59aa600c);

        batchBurnERC721.usersReceiveMERLRewards(1, 390000000000000000000, rootList);

        assertEq(testToken.balanceOf(0x000D21da4B478B0406E5EAe9c61615Be5177Fa0B), 390000000000000000000);
    }

        function testFail_UsersReceiveMERLRewardsNotSetReceiveRoot() public {
        vm.startPrank(initialOwner, initialOwner);

        testToken.mint(address(batchBurnERC721), 10000000 ether);

        batchBurnERC721.setReceiveOpen();
        batchBurnERC721.setTokenAddress(1, address(testToken));

        vm.startPrank(0x000D21da4B478B0406E5EAe9c61615Be5177Fa0B, 0x000D21da4B478B0406E5EAe9c61615Be5177Fa0B);

        bytes32[] memory rootList = new bytes32[](11);
        rootList[0] = bytes32(0xaa7a18f410d25884a48c3a2eac86383440896bbc61f87e06bbcf67dddbd15f86);
        rootList[1] = bytes32(0xa669c2c44fa87db3db0daadbf843a0d690e53f29e3733a85525edc931e24177a);
        rootList[2] = bytes32(0x45f6e8c99847b8131fd3998d132976883476fa9215d8f8feeca7f19ca13a4728);
        rootList[3] = bytes32(0x7f1d20029a45d43c29d4877159be0aa1a2f42b028142995a5b68c779a2e71a27);
        rootList[4] = bytes32(0x334323b897cabb7c9bbf377c4d1dcf5c3571fa053f06e3bb1a4e399c04fb126b);
        rootList[5] = bytes32(0x9aa38ebc7c41a74c41418fda86a2dcbacc94df119caa2086d895d3074468e7c0);
        rootList[6] = bytes32(0x05d84b3564394fdd1d97a46a1bdf0cfcfcf415d0ae58bc3cc35a0445dab773f7);
        rootList[7] = bytes32(0x1cc10da7ffc67dc3b1e62d896389911e84e5be0cefe574cf1ace5cb1414d234c);
        rootList[8] = bytes32(0x30fadabc57a81136f55f324503e3569538d9ba7f4750f27ad57c7901649d92d1);
        rootList[9] = bytes32(0x8a63a9d3be13ffc6f49175f562faa8e0680c06d96210b087d54dce78ce623201);
        rootList[10] = bytes32(0x8d57be6e031740c2062c538243791730562ce7f86adf3843416d867b59aa600c);

        batchBurnERC721.usersReceiveMERLRewards(1, 390000000000000000000, rootList);

        assertEq(testToken.balanceOf(0x000D21da4B478B0406E5EAe9c61615Be5177Fa0B), 390000000000000000000);
    }

    function testFail_UsersReceiveMERLRewardsDone() public {
        vm.startPrank(initialOwner, initialOwner);

        testToken.mint(address(batchBurnERC721), 10000000 ether);

        batchBurnERC721.setReceiveOpen();
        batchBurnERC721.setReceiveRoot(0xb0b5be6637cbb40bdf9d0528e1ab6100eed4b538f439e54d329c7cc85667f975);

        vm.startPrank(0x000D21da4B478B0406E5EAe9c61615Be5177Fa0B, 0x000D21da4B478B0406E5EAe9c61615Be5177Fa0B);

        bytes32[] memory rootList = new bytes32[](11);
        rootList[0] = bytes32(0xaa7a18f410d25884a48c3a2eac86383440896bbc61f87e06bbcf67dddbd15f86);
        rootList[1] = bytes32(0xa669c2c44fa87db3db0daadbf843a0d690e53f29e3733a85525edc931e24177a);
        rootList[2] = bytes32(0x45f6e8c99847b8131fd3998d132976883476fa9215d8f8feeca7f19ca13a4728);
        rootList[3] = bytes32(0x7f1d20029a45d43c29d4877159be0aa1a2f42b028142995a5b68c779a2e71a27);
        rootList[4] = bytes32(0x334323b897cabb7c9bbf377c4d1dcf5c3571fa053f06e3bb1a4e399c04fb126b);
        rootList[5] = bytes32(0x9aa38ebc7c41a74c41418fda86a2dcbacc94df119caa2086d895d3074468e7c0);
        rootList[6] = bytes32(0x05d84b3564394fdd1d97a46a1bdf0cfcfcf415d0ae58bc3cc35a0445dab773f7);
        rootList[7] = bytes32(0x1cc10da7ffc67dc3b1e62d896389911e84e5be0cefe574cf1ace5cb1414d234c);
        rootList[8] = bytes32(0x30fadabc57a81136f55f324503e3569538d9ba7f4750f27ad57c7901649d92d1);
        rootList[9] = bytes32(0x8a63a9d3be13ffc6f49175f562faa8e0680c06d96210b087d54dce78ce623201);
        rootList[10] = bytes32(0x8d57be6e031740c2062c538243791730562ce7f86adf3843416d867b59aa600c);

        batchBurnERC721.usersReceiveMERLRewards(1, 390000000000000000000, rootList);
        batchBurnERC721.usersReceiveMERLRewards(1, 390000000000000000000, rootList);
    }

    function testUsersReceiveMERLRewards() public {
        vm.startPrank(initialOwner, initialOwner);

        testToken.mint(address(batchBurnERC721), 10000000 ether);
        batchBurnERC721.setTokenAddress(1, address(testToken));

        batchBurnERC721.setReceiveOpen();
        batchBurnERC721.setReceiveRoot(0xb0b5be6637cbb40bdf9d0528e1ab6100eed4b538f439e54d329c7cc85667f975);

        vm.startPrank(0x000D21da4B478B0406E5EAe9c61615Be5177Fa0B, 0x000D21da4B478B0406E5EAe9c61615Be5177Fa0B);

        bytes32[] memory rootList = new bytes32[](11);
        rootList[0] = bytes32(0xaa7a18f410d25884a48c3a2eac86383440896bbc61f87e06bbcf67dddbd15f86);
        rootList[1] = bytes32(0xa669c2c44fa87db3db0daadbf843a0d690e53f29e3733a85525edc931e24177a);
        rootList[2] = bytes32(0x45f6e8c99847b8131fd3998d132976883476fa9215d8f8feeca7f19ca13a4728);
        rootList[3] = bytes32(0x7f1d20029a45d43c29d4877159be0aa1a2f42b028142995a5b68c779a2e71a27);
        rootList[4] = bytes32(0x334323b897cabb7c9bbf377c4d1dcf5c3571fa053f06e3bb1a4e399c04fb126b);
        rootList[5] = bytes32(0x9aa38ebc7c41a74c41418fda86a2dcbacc94df119caa2086d895d3074468e7c0);
        rootList[6] = bytes32(0x05d84b3564394fdd1d97a46a1bdf0cfcfcf415d0ae58bc3cc35a0445dab773f7);
        rootList[7] = bytes32(0x1cc10da7ffc67dc3b1e62d896389911e84e5be0cefe574cf1ace5cb1414d234c);
        rootList[8] = bytes32(0x30fadabc57a81136f55f324503e3569538d9ba7f4750f27ad57c7901649d92d1);
        rootList[9] = bytes32(0x8a63a9d3be13ffc6f49175f562faa8e0680c06d96210b087d54dce78ce623201);
        rootList[10] = bytes32(0x8d57be6e031740c2062c538243791730562ce7f86adf3843416d867b59aa600c);

        batchBurnERC721.usersReceiveMERLRewards(1, 390000000000000000000, rootList);

        assertEq(testToken.balanceOf(0x000D21da4B478B0406E5EAe9c61615Be5177Fa0B), 390000000000000000000);
    }
}

//forge test -vvv --root . -C contracts/src --match-path contracts/test/merlinChain/BatchBurnERC721.t.sol --out forge-artifacts
