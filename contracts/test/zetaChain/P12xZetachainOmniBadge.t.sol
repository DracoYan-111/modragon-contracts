// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import {P12xZetachainOmniBadge} from "../../src/zetaChain/P12xZetachainOmniBadge.sol";

contract P12xZetachainOmniBadgeTest is Test, IERC721Receiver {
    bytes32 private constant TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant WHITELIST_MINT = keccak256("WhitelistMint(address user,uint256 deadline)");

    uint256 public constant INITIALOWNERKEY = 0xde9be858da4a475276426320d5e9262ecfc3ba460bfac56360bfa6c4c28b4ee0;
    uint256 public constant SIGNERPRIVATEKEY = 0xdf57089febbacf7ba0bc227dafbffa9fc08a93fdc68e1e42411a14efcf23656e;

    string public name;
    string public constant VERSION = "V1.0.0";

    string public constant TOKNE_URI = "token uri";
    string public constant NEW_TOKNE_URI = "new token uri";

    address public initialOwner;
    address public signerAddress;

    P12xZetachainOmniBadge public p12xZetachainOmniBadgeTeest;

    // /**
    //  * @dev Sets up the test.
    //  */
    // function setUp() external {
    //     initialOwner = vm.addr(INITIALOWNERKEY);
    //     signerAddress = vm.addr(SIGNERPRIVATEKEY);

    //     p12xZetachainOmniBadgeTeest = new P12xZetachainOmniBadge();
    //     p12xZetachainOmniBadgeTeest.initialize(address(0), TOKNE_URI, signerAddress);
    //     name = p12xZetachainOmniBadgeTeest.name();
    // }

    // function testOwnerEq() external {
    //     assertEq(p12xZetachainOmniBadgeTeest.owner(), initialOwner);
    // }

    // function testTokenURIEq() external {
    //     assertEq(p12xZetachainOmniBadgeTeest.tokenURI(0), TOKNE_URI);
    // }

    // function testFail_SetTokenURI() external {
    //     p12xZetachainOmniBadgeTeest.updateTokenUri(NEW_TOKNE_URI);
    // }

    // function testSetTokenURI() external {
    //     vm.prank(initialOwner);
    //     p12xZetachainOmniBadgeTeest.updateTokenUri(NEW_TOKNE_URI);
    //     assertEq(p12xZetachainOmniBadgeTeest.tokenURI(0), NEW_TOKNE_URI);
    // }

    // function testFail_SetSigner() external {
    //     p12xZetachainOmniBadgeTeest.updateSigner(signerAddress);
    // }

    // function testSetSigner() external {
    //     vm.prank(initialOwner);
    //     p12xZetachainOmniBadgeTeest.updateSigner(signerAddress);
    // }

    // function testPause() external {
    //     vm.prank(initialOwner);
    //     p12xZetachainOmniBadgeTeest.pause();
    //     vm.prank(initialOwner);
    //     p12xZetachainOmniBadgeTeest.unpause();
    // }

    function testWhitelistMint() external {
        uint256 deadline = 2705755809;

        bytes32 typedDataHash = getTypedDataHash(deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNERPRIVATEKEY, typedDataHash);

        bytes32 vs = s | (bytes32(uint256(v - 1)) << 255);
        signerAddress = vm.addr(SIGNERPRIVATEKEY);

        console.logAddress(signerAddress);
        console.logUint(deadline);
        console.logBytes32(r);
        console.logBytes32(vs);
        // p12xZetachainOmniBadgeTeest.whitelistMint(deadline, r, vs);

        // assertEq(p12xZetachainOmniBadgeTeest.getUserReceive(address(this)), true);
    }

    function getTypedDataHash(uint256 deadline) private pure returns (bytes32 typedDataHash) {
        bytes32 structHash = keccak256(
            abi.encode(WHITELIST_MINT, 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, deadline)
        );

        bytes32 domainSeparator = keccak256(
            abi.encode(
                TYPE_HASH,
                keccak256(bytes("P12 x Zetachain OmniBadge")),
                keccak256(bytes(VERSION)),
                1,
                0xD7ACd2a9FD159E69Bb102A1ca21C9a3e3A5F771B
            )
        );

        typedDataHash = MessageHashUtils.toTypedDataHash(domainSeparator, structHash);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
