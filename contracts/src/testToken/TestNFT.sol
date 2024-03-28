// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestNFT is ERC721, Ownable {
    uint256 private _nextTokenId;

    constructor(address initialOwner, string memory name) ERC721(name, name) Ownable(initialOwner) {}

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    function batchSafeMint(address to, uint256 amount) public onlyOwner {
        for (uint256 i; i < amount; ) {
            uint256 tokenId = _nextTokenId++;
            _safeMint(to, tokenId);
            unchecked {
                ++i;
            }
        }
    }
}
