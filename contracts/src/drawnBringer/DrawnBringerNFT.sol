// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

error  MintExpired();
error  AlreadyReceived();
error  InvalidSignature();

contract DrawnBringerNFT is ERC721, EIP712, Ownable, ERC721Pausable, ERC721Burnable {
    bytes32 private constant WHITELIST_MINT= keccak256("whitelistMint(address user,uint256 deadline)"); 
    address private _signer;

    string private  _tokenURI;
    uint256 private _nextTokenId;

    mapping(address => bool) public userReceive;

    modifier isReceive() {
        if(userReceive[msg.sender]) revert AlreadyReceived();
        _;
    }

    constructor(
        string memory _tokenUri,
        address _initialOwner,
        address _signerAddress
        )
        ERC721("The Dawnbringer", "TDB")
        EIP712("The Dawnbringer", "V1.0.0")
        Ownable(_initialOwner)
    {
        _tokenURI = _tokenUri;
        _signer = _signerAddress;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function updateTokenUri(string calldata newTokenUri) public onlyOwner{
        _tokenURI = newTokenUri;
    }

    function updateSigners(address newSigner) public onlyOwner{
        _signer = newSigner;
    }

    function whitelistMint(
        uint256 deadline, 
        bytes32 r, 
        bytes32 vs) public whenNotPaused{
        if (deadline < block.timestamp) revert MintExpired();

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    WHITELIST_MINT, msg.sender, deadline
                    )
                )
            );

        (address recovered,, ) = ECDSA.tryRecover(digest,  r, vs);
        if(recovered != _signer) revert InvalidSignature();

        _mint(msg.sender);

        userReceive[msg.sender] = true;
    }

    // The following functions are overrides required by Solidity.
    function tokenURI(uint256)public view override(ERC721) returns (string memory){
        return _tokenURI;
    }

    function _mint(address to) private {
        _safeMint(to, ++_nextTokenId);
    }

    function _update(
        address to,
        uint256 tokenId, 
        address auth)internal override(ERC721, ERC721Pausable) returns (address){
        return super._update(to, tokenId, auth);
    }
}