// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./storage/MoDragonContractStorage.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

error Expired(uint256 deadline);
error InvalidSignature();

contract MoDragonContract is ERC721, EIP712, Ownable, ERC721Pausable, ERC721Burnable, MoDragonContractStorage {
    bytes32 private constant WHITELIST_MINT= keccak256("whitelistMint(address user,uint256 deadline)"); 
    address private immutable _signers;

    uint256 private _nextTokenId;
    string private  _tokenURI;

    constructor(
        string memory _tokenUri,
        address _initialOwner,
        address _signerAddress
        )
        ERC721("qqqqq", "qq")
        EIP712("qqqqq", "V1.0.0")
        Ownable(_initialOwner)
    {
        _tokenURI = _tokenUri;
        _signers = _signerAddress;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to) public onlyOwner whenPaused{
        _mint(to);
    }

    function whitelistMint(uint256 deadline, bytes memory signature) public whenNotPaused{
        if (deadline > block.timestamp) revert Expired(block.timestamp);

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    WHITELIST_MINT, msg.sender, deadline
                    )
                )
            );
        if(ECDSA.recover(digest, signature) != _signers) revert InvalidSignature();
        _mint(msg.sender);
    }

    function _mint(address to) private {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function tokenURI(uint256)public view override(ERC721) returns (string memory){
        return _tokenURI;
    }

    function _update(
        address to,
        uint256 tokenId, 
        address auth
        )internal override(ERC721, ERC721Pausable)returns (address){
        return super._update(to, tokenId, auth);
    }


}
