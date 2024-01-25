// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IP12xZetachainOmniBadgeDef {
    error MintExpired();
    error AlreadyReceived();
    error InvalidSignature();

    event SetSigner(address newSigner);
    event SetTokenUri(string newTokenURI);
    event SetSystemContract(address newSystemContract);
    event UserHasReceived(uint256 indexed tokenID, address indexed userAddress);
}

interface IP12xZetachainOmniBadge is IP12xZetachainOmniBadgeDef {}
