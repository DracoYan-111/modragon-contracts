// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IDragonBallBurnDef {
    error ChainAddressCheckFailed();

    event OwnerWithdraw(address tokenAddress, uint256[] tokenAmount, address recipientAddr);
    event UserBurnNft(uint256 burnAmount, address targetAddress);
}

interface IDragonBallBurn is IDragonBallBurnDef {}
