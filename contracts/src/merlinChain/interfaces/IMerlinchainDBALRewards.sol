// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract IMerlinchainDBALRewardsDef {
    error EventIsClosed();
    error UserHasReceived();
    error MerkleVerifiFailed();
    error MBTCTransferFailed();
    error IncorrectMintAmount();
    error IncorrectMintQuantity();
    error InsufficientMBTCBalance();

    event UserHasReceivedDBAL();
    event UserHasReceivedRefund();
    event UserMint(uint256 quantity, address tokenAddress);
    event SetTokenAddress(uint256 number, address tokenAddress);
    event SetMerkleRootInformation(uint256 functionName, bytes32 merkleRoot);
}

contract IMerlinchainDBALRewards is IMerlinchainDBALRewardsDef {}
