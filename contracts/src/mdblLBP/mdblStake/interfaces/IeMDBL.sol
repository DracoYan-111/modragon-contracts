// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IeMDBLDef {
    error MulWadFailed();
    error InvalidAmount();
    error InvalidDuration();
    error RedemptionFinish();
    error RedemptionNotEnded();
    error NoMintLimitAvailable();
    error NotEnoughAvailableAmount();

    event UpdateSigner(address signer);
    event UserSwapEMDBL(address user, uint256 amount, uint256 timestamp);
    event PermitMintToken(address user, uint256 amount);
    event RedemptionStarted(address user, uint256 duration, uint256 timestamp, uint256 amount, uint256 index);
    event RedemptionCancelled(address user, uint256 index);
    event RedemptionCompleted(address user, uint256 index);
}

interface IeMDBL is IeMDBLDef {}
