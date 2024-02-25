// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IDragonBallHatchDef {
    error EventIsClosed();
    error BTCPaymentFailed();
    error BTCTransferFailed();
    error InsufficientBTCBalance();

    event OwnerWithdraw(address tokenAddress, uint256 tokenAmount, address recipientAddr);
    event UserHatching(string bizId, address paymentToken, uint256 paymentAmount, address senderAddress);
}

interface IDragonBallHatch is IDragonBallHatchDef {}
