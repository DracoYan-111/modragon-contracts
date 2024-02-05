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

    event UserMint();
    event UserHasReceivedDBAL();
    event UserHasReceivedRefund();
    event SetMerkleRootInformation(uint256 functionName, bytes32 merkleRoot);
}

contract IMerlinchainDBALRewards is IMerlinchainDBALRewardsDef {}
