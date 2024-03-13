// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IRewardDistributionDef {
    error AlreadyReceived();
    error VerificationFailed();

    event Claimed(address, uint256[]);
    event SetTokenAddress(uint256, address);
    event SetMerkleRootInformation(uint256, bytes32);
    event UserBurnNft(uint256 burnAmount, address targetAddress);
    event OwnerWithdraw(address tokenAddress, uint256[] tokenAmount, address recipientAddr);
}

interface IRewardDistribution is IRewardDistributionDef {}
