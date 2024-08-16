// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {UUPSUpgradeable, Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {IRankTokenDistribution} from "./interfaces/IRankTokenDistribution.sol";

contract RankTokenDistribution is
    Initializable,
    PausableUpgradeable,
    Ownable2StepUpgradeable,
    ReentrancyGuardUpgradeable,
    IRankTokenDistribution,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    // keccak256(abi.encode(uint256(keccak256("RankTokenDistributionStorage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant RankTokenDistributionStorageLocation =
        0x12eccda39a912e3db87acc3ba69815bb09f308eb3f31f6e92e1723d50cf67800;

    struct RankTokenDistributionStorage {
        uint256 season;
        mapping(uint256 => IERC20) seasonTokenAddress;
        mapping(uint256 => bytes32) seasonReceiveRoot;
        mapping(uint256 => mapping(address => uint256)) seasonUserHasUsedAward;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __Pausable_init();
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


    /**
     * @dev Update season data 
     * @param newSeason New season id
     * @param newTokenAddress Token address
     * @param newReceiveRoot Merkle root
     */
    function setSeasonData(uint256 newSeason, IERC20 newTokenAddress, bytes32 newReceiveRoot) external onlyOwner {
        RankTokenDistributionStorage storage $ = _getRankTokenDistributionStorage();

        $.season = newSeason;
        $.seasonReceiveRoot[newSeason] = newReceiveRoot;
        $.seasonTokenAddress[newSeason] = newTokenAddress;

        emit UpdateSeasonData(newSeason, address(newTokenAddress));
    }

    /**
     * @dev Claim token rewards
     * @param index Index corresponding to user address
     * @param amount Token amount
     * @param merkleProof Merkle proof
     */
    function usersReceiveTokenRewards(
        uint256 index,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external nonReentrant whenNotPaused {
        RankTokenDistributionStorage storage $ = _getRankTokenDistributionStorage();

        uint256 currentSeason = $.season;
        if ($.seasonReceiveRoot[currentSeason] == bytes32(0)) revert ReceiveRootNotSet();
        if (amount == $.seasonUserHasUsedAward[currentSeason][msg.sender]) revert UserHasNotUseToken();

        // Verify the merkle proof.
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(index, msg.sender, amount))));
        if (!MerkleProof.verify(merkleProof, $.seasonReceiveRoot[currentSeason], leaf)) revert VerificationFailed();

        uint256 transferAmount = amount - $.seasonUserHasUsedAward[currentSeason][msg.sender];
        $.seasonUserHasUsedAward[currentSeason][msg.sender] += transferAmount;

        IERC20 seasontRewardToken = $.seasonTokenAddress[currentSeason];
        if (seasontRewardToken.balanceOf(address(this)) < transferAmount)
            revert NotEnoughRewardTokens();

        seasontRewardToken.safeTransfer(msg.sender, transferAmount);

        emit PermitClaimToken(address(seasontRewardToken), msg.sender, transferAmount);
    }

    /**
     * Get user rewards
     * @param seasonId Season id
     * @param userAddress User address
     * @return User rewards
     */
    function getUserRewardsReceived(uint256 seasonId, address userAddress) public view returns ( uint256) {
        RankTokenDistributionStorage storage $ = _getRankTokenDistributionStorage();

        return $.seasonUserHasUsedAward[seasonId][userAddress];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function _getRankTokenDistributionStorage() private pure returns (RankTokenDistributionStorage storage $) {
        assembly {
            $.slot := RankTokenDistributionStorageLocation
        }
    }
}
