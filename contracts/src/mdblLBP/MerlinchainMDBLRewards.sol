// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {ReentrancyGuardUpgradeable, Initializable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {IMerlinchainMDBLRewards} from "./interfaces/IMerlinchainMDBLRewards.sol";

contract MerlinchainMDBLRewards is
    Initializable,
    UUPSUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    Ownable2StepUpgradeable,
    IMerlinchainMDBLRewards
{
    using MerkleProof for bytes32;
    using BitMaps for BitMaps.BitMap;

    // keccak256(abi.encode(uint256(keccak256("RewardDistributionStorage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant RewardDistributionStorageLocation =
        0xc813d4db6d7c98627990ff59b98f06d051ef2ace123bcd93288a94535909cf00;

    struct RewardDistributionStorage {
        IERC20 MDBLAddress;
        bytes32 receiveRoot;
        BitMaps.BitMap userReceive;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address _initialOwner, IERC20 _MDBLAddress, bytes32 _receiveRoot) public initializer {
        RewardDistributionStorage storage $ = _getRewardDistributionStorage();

        $.MDBLAddress = _MDBLAddress;
        $.receiveRoot = _receiveRoot;

        __Ownable_init(_initialOwner);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Update merkle root data only owner
     * @param merkleRoot Merkle root data
     */
    function updateMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        RewardDistributionStorage storage $ = _getRewardDistributionStorage();

        $.receiveRoot = merkleRoot;

        emit SetMerkleRootInformation(merkleRoot);
    }

    /**
     * @dev Update token address only owner
     * @param newTokenAddress New token address
     */
    function updateTokenAddress(IERC20 newTokenAddress) external onlyOwner {
        RewardDistributionStorage storage $ = _getRewardDistributionStorage();

        $.MDBLAddress = newTokenAddress;

        emit SetTokenAddress(address(newTokenAddress));
    }

    /**
     * @dev Owner withdraw tokens
     * @param recipientAddr Recipient address
     */
    function withdrawTokens(address recipientAddr) external onlyOwner {
        RewardDistributionStorage storage $ = _getRewardDistributionStorage();

        $.MDBLAddress.transfer(recipientAddr, $.MDBLAddress.balanceOf(address(this)));

        emit OwnerWithdraw(recipientAddr);
    }

    /**
     * @dev Check whether the index corresponding to the user is used
     * @param index Index corresponding to user address
     */
    function isClaimed(uint256 index) public view returns (bool) {
        RewardDistributionStorage storage $ = _getRewardDistributionStorage();

        return $.userReceive.get(index);
    }

    /**
     * @dev Claim NFT
     * @param index Index corresponding to user address
     * @param amount  Array of NFT IDs to be collected
     * @param merkleProof Merkle proof
     */
    function claim(uint256 index, uint256 amount, bytes32[] calldata merkleProof) external nonReentrant whenNotPaused {
        RewardDistributionStorage storage $ = _getRewardDistributionStorage();

        if (isClaimed(index)) revert AlreadyReceived();

        // Verify the merkle proof.
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(index, msg.sender, amount))));
        if (!MerkleProof.verify(merkleProof, $.receiveRoot, leaf)) revert VerificationFailed();

        // Update user receive
        $.userReceive.set(index);

        $.MDBLAddress.transfer(msg.sender, amount);
        emit Claimed(msg.sender, amount);
    }

    function _getRewardDistributionStorage() private pure returns (RewardDistributionStorage storage $) {
        assembly {
            $.slot := RewardDistributionStorageLocation
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
