// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
struct zContext {
    bytes origin;
    address sender;
    uint256 chainID;
}

interface zContract {
    function onCrossChainCall(
        zContext calldata context,
        address zrc20,
        uint256 amount,
        bytes calldata message
    ) external;
}

interface IP12xZetachainOmniBadgeDef {
    // =========== ERROR ==========
    // error MintExpired();
    error NonSystemContract();

    error AlreadyReceivedNFT();
    error AlreadyReceivedCost();

    // error InvalidSignature();
    error ZETATransferFailed();
    error IncorrectAmountZETA();
    error InsufficientZETABalance();

    error votingHasEnded();
    error UserVotedThatDay();
    error MintBehaviorNotChecked();
    error ReceiveCostTimeNotArrived();

    // =========== EVENT ==========
    event SetSigner(address newSigner);
    event SetTokenUri(string newTokenURI);
    event SetPayQuantity(uint256 newPayQuantity);
    event SetSystemContract(address newSystemContract);
    event SetVoteStartTimeAndDurationDays(uint256 newVoteStartTimeAndDurationDays);

    event CollectionStartsStatus(bool indexed isOpen);

    event UserHasReceivedCost(address indexed userAddress);
    event UserHasReceivedNFT(uint256 indexed tokenID, address indexed userAddress);
    event UserVoteForGameID(address indexed userAddress, uint256 indexed timeStamp, uint256 indexed gameID);
}

interface IP12xZetachainOmniBadge is IP12xZetachainOmniBadgeDef {}
