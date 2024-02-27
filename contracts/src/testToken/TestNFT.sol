// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract TestNFT is ERC721, ERC721Enumerable, Ownable {
    uint256 private _nextTokenId;

    constructor(address initialOwner) ERC721("TestNFT", "TestNFT") Ownable(initialOwner) {}

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function getDragonsWallet(
        address userAddress
    ) external view returns (uint256[] memory tokenIds, uint256[] memory attrs) {
        tokenIds = new uint256[](super.balanceOf(userAddress));
        for (uint256 i; i < tokenIds.length; ) {
            tokenIds[i] = super.tokenOfOwnerByIndex(userAddress, i);
            unchecked {
                ++i;
            }
        }

        attrs = new uint256[](tokenIds.length * 12);
        uint256[] memory attrsNFT;
        uint256 cursor = 0;
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            attrsNFT = getDragonByTokenId(tokenIds[i]);
            for (uint256 j = 0; j < 12; ++j) {
                attrs[cursor++] = attrsNFT[j];
            }
        }
    }

    function getDragonByTokenId(uint256 tokenId) public pure returns (uint256[] memory attrs) {
        attrs = new uint256[](12);
        attrs[0] = uint256(tokenId);
        attrs[1] = uint256(777);
        attrs[2] = uint256(1048579);
        attrs[3] = uint256(10);
        attrs[4] = uint256(48);
        attrs[5] = uint256(3);
        attrs[6] = uint256(1);
        attrs[7] = uint256(10);
        attrs[8] = uint256(1039273);
        attrs[9] = uint256(1022125);
        attrs[10] = uint256(2063597568);
        attrs[11] = uint256(0);
    }
}
