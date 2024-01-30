// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {EIP712Upgradeable, Initializable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {ERC721PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";

import {IP12xZetachainOmniBadge} from "./interfaces/IP12xZetachainOmniBadge.sol";
import {ISystemContract, zContract, zContext} from "./interfaces/ISystemContract.sol";

contract P12xZetachainOmniBadge is
    Initializable,
    UUPSUpgradeable,
    EIP712Upgradeable,
    ERC721Upgradeable,
    ReentrancyGuardUpgradeable,
    ERC721PausableUpgradeable,
    Ownable2StepUpgradeable,
    IP12xZetachainOmniBadge,
    zContract
{
    using BitMaps for BitMaps.BitMap;

    bytes32 private constant WHITELIST_MINT = keccak256("WhitelistMint(address user,uint256 deadline)");

    // keccak256(abi.encode(uint256(keccak256("P12xZetachainOmniBadgeStorage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant P12xZetachainOmniBadgeStorageLocation =
        0x1cd131e6d0ca7e68ef19f43129322449a3aeef57e2f4bd8760e571742140ec00;

    struct P12xZetachainOmniBadgeStorage {
        string _tokenURI;
        uint64 payQuantity;
        uint128 _nextTokenId;
        bool collectionStarts;
        BitMaps.BitMap userReceiveNFT;
        BitMaps.BitMap userReceiveCost;
        uint256 voteStartTimeAndDurationDays;
        mapping(address => uint256) userPaysFees;
        mapping(address => mapping(uint256 => uint256)) userVotingStatus;
        ISystemContract systemContract;
    }

    modifier onlyCanMintOnceAndVerifyPayment() {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        if (msg.value != $.payQuantity) revert IncorrectAmountZETA();
        if ($.userReceiveNFT.get(uint256(uint160(msg.sender)))) revert AlreadyReceivedNFT();

        _;
    }

    modifier onlyCanOpenAndReceivedOnce() {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        if (!$.collectionStarts) revert ReceiveCostTimeNotArrived();
        if (!BitMaps.get($.userReceiveCost, uint256(uint160(msg.sender))) && $.userPaysFees[msg.sender] == 0)
            revert AlreadyReceivedCost();

        _;
    }

    modifier onlyDaysUpdateAndMintBehavior() {
        uint256 voteDays = getVoteDays();

        if (voteDays == getVotingDurationDays()) revert votingHasEnded();
        if (!getUserReceiveNFT(msg.sender)) revert MintBehaviorNotChecked();
        if (getUserVoteEligibility(msg.sender, voteDays)) revert UserVotedThatDay();

        _;
    }

    modifier onlySystem() {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        if (msg.sender != address($.systemContract)) revert NonSystemContract();

        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint256 _voteStartTimeAndDurationDays,
        address _systemContractAddress,
        string memory _tokenUri,
        address _initialOwner,
        uint64 _payQuantity
    ) public initializer {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        $._tokenURI = _tokenUri;
        $.payQuantity = _payQuantity;
        $.systemContract = ISystemContract(_systemContractAddress);
        $.voteStartTimeAndDurationDays = _voteStartTimeAndDurationDays;

        __ERC721_init("P12 x Zetachain OmniBadge", "P12 x Zetachain OmniBadge");
        __EIP712_init("P12 x Zetachain OmniBadge", "V1.0.0");
        __Ownable_init(_initialOwner);
        __ERC721Pausable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
    }

    /**
     * @dev Pause related functions(only owner)
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Turn on related functions(only owner)
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Update token uri(only owner)
     * @param newTokenUri New token uri
     */
    function updateTokenUri(string calldata newTokenUri) external onlyOwner {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        $._tokenURI = newTokenUri;

        emit SetTokenUri(newTokenUri);
    }

    /**
     * @dev Update user pay quantity(only owner)
     * @param newPayQuantity New pay native token quantity
     */
    function updatePayQuantity(uint64 newPayQuantity) external onlyOwner {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        $.payQuantity = newPayQuantity;

        emit SetPayQuantity(newPayQuantity);
    }

    /**
     * @dev Update vote start time and vote duration days(only owner)
     * @param newVoteStartTimeAndDurationDays New vote start time and duration days
     */
    function updateVoteStartTimeAndDurationDays(uint256 newVoteStartTimeAndDurationDays) external onlyOwner {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        $.voteStartTimeAndDurationDays = newVoteStartTimeAndDurationDays;

        emit SetVoteStartTimeAndDurationDays(newVoteStartTimeAndDurationDays);
    }

    /**
     * @dev Update system contract address(only owner)
     * @param newSystemContract New signer adress
     */
    function updateSystemContract(address newSystemContract) external onlyOwner {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        $.systemContract = ISystemContract(newSystemContract);

        emit SetSystemContract(newSystemContract);
    }

    function openCollectionStarts() external onlyOwner {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        $.collectionStarts = !$.collectionStarts;

        emit CollectionStartsStatus($.collectionStarts);
    }

    /**
     * @dev User pays ZETA mint NFT
     */
    function openMint() external payable nonReentrant whenNotPaused onlyCanMintOnceAndVerifyPayment {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        $.userReceiveNFT.setTo(uint256(uint160(msg.sender)), true);
        $.userReceiveCost.setTo(uint256(uint160(msg.sender)), true);

        _mint(msg.sender);

        $.userPaysFees[msg.sender] = msg.value;

        emit UserHasReceivedNFT($._nextTokenId, msg.sender);
    }

    /**
     * @dev User receive the ZETA paid by mint cost
     */
    function userReceiveMintCost() external nonReentrant whenNotPaused onlyCanOpenAndReceivedOnce {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        $.userReceiveCost.setTo(uint256(uint160(msg.sender)), false);

        uint256 userMintFee = $.userPaysFees[msg.sender];
        $.userPaysFees[msg.sender] -= userMintFee;

        _callSendZETA(msg.sender, userMintFee);

        emit UserHasReceivedCost(msg.sender);
    }

    /**
     * @dev Users vote for their favorite games
     * @param gameId User favorite game id
     */
    function userFavoriteGameVote(uint256 gameId) external nonReentrant whenNotPaused onlyDaysUpdateAndMintBehavior {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        uint256 voteDays = getVoteDays();
        $.userVotingStatus[msg.sender][voteDays] = gameId;

        emit UserVoteForGameID(msg.sender, block.timestamp, gameId, voteDays);
    }

    /**
     * @dev Check whether the user has received it NFT
     * @param userAddress Check user address
     * @return true/false
     */
    function getUserReceiveNFT(address userAddress) public view returns (bool) {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        return BitMaps.get($.userReceiveNFT, uint256(uint160(userAddress)));
    }

    /**
     * @dev Check whether the user has received it token
     * @param userAddress Check user address
     * @return true/false
     */
    function getUserReceiveCost(address userAddress) public view returns (bool) {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        return BitMaps.get($.userReceiveCost, uint256(uint160(userAddress)));
    }

    /**
     * @dev Check user mint NFT cost
     * @return user mint pay quantity
     */
    function getPayQuantity() public view returns (uint256) {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        return $.payQuantity;
    }

    /**
     * @dev Check current voting maintenance days
     * @return Voting maintenance days
     */
    function getVoteDays() public view returns (uint256) {
        // Calculate the number of days that have passed
        uint256 countDays = (block.timestamp - getVotingStartTime()) / 1 days;

        //Take the smaller value between the number of days in the past
        //and the number of days voting lasts to prevent users from casting invalid votes.
        return countDays < getVotingDurationDays() ? countDays : getVotingDurationDays();
    }

    /**
     * @dev Check if the current user can vote
     * @param userAddress User address to be queried
     * @return true/false
     */
    function getUserVoteEligibility(address userAddress, uint256 day) public view returns (bool) {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        return $.userVotingStatus[userAddress][day] > 0;
    }

    /**
     * @dev Check voting start time
     * @return Voting start time
     */
    function getVotingStartTime() public view returns (uint256) {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        return $.voteStartTimeAndDurationDays >> 64;
    }

    /**
     * @dev Check voting duration days
     * @return Voting duration days
     */
    function getVotingDurationDays() public view returns (uint256) {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        return $.voteStartTimeAndDurationDays & 0xFFFFFFFFFFFFFFFF;
    }

    // The following functions are overrides required by Solidity.

    /**
     * @dev Check token uri
     * @return token uri
     */
    function tokenURI(uint256) public view override returns (string memory) {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        return $._tokenURI;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function onCrossChainCall(
        zContext calldata context,
        address zrc20,
        uint256 amount,
        bytes calldata message
    ) external virtual override onlySystem {
        // TODO: implement the logic
    }

    function _getP12xZetachainOmniBadgeStorage() private pure returns (P12xZetachainOmniBadgeStorage storage $) {
        assembly {
            $.slot := P12xZetachainOmniBadgeStorageLocation
        }
    }

    function _mint(address to) private {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        _safeMint(to, ++$._nextTokenId);
    }

    function _callSendZETA(address userAddress, uint256 amount) private {
        if (amount > address(this).balance) revert InsufficientZETABalance();

        (bool sent, ) = payable(userAddress).call{value: amount}("");

        if (!sent) revert ZETATransferFailed();
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721Upgradeable, ERC721PausableUpgradeable) returns (address) {
        return super._update(to, tokenId, auth);
    }
}
