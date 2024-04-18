// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IMerlinchainMDBLRewardsDef {
    error AlreadyReceived();
    error VerificationFailed();

    event Claimed(address, uint256);
    event SetTokenAddress(address);
    event SetMerkleRootInformation(bytes32);
    event OwnerWithdraw(address);
}

interface IMerlinchainMDBLRewards is IMerlinchainMDBLRewardsDef {}
