// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ERC721Pausable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

error MintExpired();
error AlreadyReceived();
error InvalidSignature();

contract DrawnBringerNFT is ERC721, EIP712, Ownable, ERC721Pausable, ERC721Burnable {
    using BitMaps for BitMaps.BitMap;

    event SetSigners(address newSigners);
    event SetTokenUri(string newTokenURI);
    event UserHasReceived(uint256 indexed tokenID, address indexed userAddress);

    bytes32 private constant WHITELIST_MINT = keccak256("WhitelistMint(address user,uint256 deadline)");
    address private _signer;

    string private _tokenURI;
    uint256 private _nextTokenId;

    BitMaps.BitMap private userReceive;

    modifier onlyCanMintOnce() {
        if (userReceive.get(uint256(uint160(msg.sender)))) revert AlreadyReceived();
        _;
    }

    constructor(string memory _tokenUri, address _initialOwner, address _signerAddress)
        ERC721("The Dawnbringer", "TDB")
        EIP712("The Dawnbringer", "V1.0.0")
        Ownable(_initialOwner)
    {
        _tokenURI = _tokenUri;
        _signer = _signerAddress;
    }

    /**
     * @dev Pause related functions(only owner)
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Turn on related functions(only owner)
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Update token uri(only owner)
     * @param newTokenUri New token uri
     */
    function updateTokenUri(string calldata newTokenUri) public onlyOwner {
        _tokenURI = newTokenUri;
        emit SetTokenUri(newTokenUri);
    }

    /**
     * @dev Update signer(only owner)
     * @param newSigner New signer adress
     */
    function updateSigners(address newSigner) public onlyOwner {
        _signer = newSigner;
        emit SetSigners(newSigner);
    }

    /**
     * @dev Whitelist mint
     * @param deadline Transaction duration
     * @param r R short-signature fields
     * @param vs VS short-signature fields
     */
    function whitelistMint(uint256 deadline, bytes32 r, bytes32 vs) public isReceive whenNotPaused {
        if (deadline < block.timestamp) revert MintExpired();

        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(WHITELIST_MINT, msg.sender, deadline)));

        (address recovered,,) = ECDSA.tryRecover(digest, r, vs);
        if (recovered != _signer) revert InvalidSignature();

        _mint(msg.sender);

        userReceive.setTo(uint256(uint160(msg.sender)), true);

        emit UserHasReceived(_nextTokenId, msg.sender);
    }

    // The following functions are overrides required by Solidity.

    /**
     * @dev Check token uri
     * @return token uri
     */
    function tokenURI(uint256) public view override(ERC721) returns (string memory) {
        return _tokenURI;
    }

    /**
     * @dev Check whether the user has received it
     * @param userAddress Check user address
     * @return true/false
     */
    function getUserReceive(address userAddress) public view returns (bool) {
        return BitMaps.get(userReceive, uint256(uint160(userAddress)));
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _mint(address to) private {
        _safeMint(to, ++_nextTokenId);
    }
}
