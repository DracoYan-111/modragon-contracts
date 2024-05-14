// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IeMDBL {
    function mint(address to, uint256 amount) external;
}

interface IBatchBurnERC721Def {
    error DivWadFailed();
    error MulWadFailed();
    error RewardsAreOpen();
    error RewardsAreNotOpen();
    error AlreadyReceived();
    error VerificationFailed();
    error CallerNotTheTokenOwner();
    error ContractNotAuthorizedToBurn();

    event UserBurn(address userAddress, uint256[] tokenIdList);
    event UsersReceiveMERLRewards(address userAddress, uint256 amount);
    event UsersReceiveeMDBLRewards(address userAddress, uint256 amount);
}

interface IBatchBurnERC721 is IBatchBurnERC721Def {}
