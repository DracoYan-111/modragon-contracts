// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IRankTokenDistributionDef {
    error ReceiveRootNotSet();
    error UserHasNotUseToken();
    error VerificationFailed();    
    error NotEnoughRewardTokens();
    
    event UpdateSeasonData(uint256 seasonId, address tokenAddress);
    event PermitClaimToken(address tokenAddress, address userAddress, uint256 amount);
}

interface IRankTokenDistribution is IRankTokenDistributionDef {}
