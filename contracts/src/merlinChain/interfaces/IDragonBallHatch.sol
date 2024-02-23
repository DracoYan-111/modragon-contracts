// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract IDragonBallHatchDef {
    error EventIsClosed();
    error BTCPaymentFailed();
    error BTCTransferFailed();
    error InsufficientBTCBalance();

    event OwnerWithdraw(address tokenAddress, uint256 tokenAmount, address userAddress);
    event UserHatching(string bizId, address tokenAddress, uint256 tokenAmount, address userAddress);
}

contract IDragonBallHatch is IDragonBallHatchDef {}
