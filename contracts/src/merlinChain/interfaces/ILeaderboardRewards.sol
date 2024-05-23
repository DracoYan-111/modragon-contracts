// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IeMDBL {
    function mint(address to, uint256 amount) external;
}

interface ILeaderboardRewardsDef {
    error UserInBlackList();
    error ERC2612ExpiredSignature(uint256 deadline);
    error ERC2612InvalidSigner(address signer, address owner);

    event UpdateSinger(address newSinger);
    event UpdateBlackList(address[] userAddress);
    event UpdateTokenAddress(address tokenAddress, uint8 opt);
    event PermitClaimToken(address tokenAddress, address userAddress, uint256 amount);
}

interface ILeaderboardRewards is ILeaderboardRewardsDef {}
