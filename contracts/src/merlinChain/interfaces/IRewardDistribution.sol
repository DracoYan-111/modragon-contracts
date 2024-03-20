// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IRewardDistributionDef {
    error AlreadyReceived();
    error VerificationFailed();

    event Claimed(address, uint256[]);
    event SetTokenAddress(uint256, address);
    event SetMerkleRootInformation(bytes32);
    event OwnerWithdraw(address, uint256[], address);
}

interface IRewardDistribution is IRewardDistributionDef {}
