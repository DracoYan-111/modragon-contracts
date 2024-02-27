// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IDragonBallBurnDef {
    error ChainAddressCheckFailed();
    error WronWithdrawTokenId(uint256 tokenId);

    event SetCheckChainId(uint256 newCheckChainId);
    event SetBurnNFTAddress(address newBurnNFTAddress);
    event UserBurnNft(uint256 burnAmount, address targetAddress);
    event OwnerWithdraw(address tokenAddress, uint256[] tokenAmount, address recipientAddr);
}

interface IDragonBallBurn is IDragonBallBurnDef {}
