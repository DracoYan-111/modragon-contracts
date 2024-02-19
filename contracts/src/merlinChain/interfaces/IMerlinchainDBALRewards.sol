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
    event SetTokenAddress(uint256 number, address tokenAddress);
    event SetTokenQuantityCharged(uint256 number, uint256 quantityCharged);
    event UserMint(uint256 quantity, uint256 totalCost, address tokenAddrss);
    event SetMerkleRootInformation(uint256 functionName, bytes32 merkleRoot);
}

contract IMerlinchainDBALRewards is IMerlinchainDBALRewardsDef {}
