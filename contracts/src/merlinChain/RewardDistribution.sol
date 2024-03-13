// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {ReentrancyGuardUpgradeable, Initializable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {IRewardDistribution} from "./interfaces/IRewardDistribution.sol";

contract RewardDistribution is
    Initializable,
    UUPSUpgradeable,
    IERC721Receiver,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    Ownable2StepUpgradeable,
    IRewardDistribution
{
    using MerkleProof for bytes32;
    using BitMaps for BitMaps.BitMap;

    // keccak256(abi.encode(uint256(keccak256("RewardDistributionStorage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant RewardDistributionStorageLocation =
        0xc813d4db6d7c98627990ff59b98f06d051ef2ace123bcd93288a94535909cf00;

    struct RewardDistributionStorage {
        IERC721 blueboxAddr;
        IERC721 musicboxAddr;
        bytes32 blueboxRoot;
        bytes32 musicboxRoot;
        BitMaps.BitMap userReceiveBluebox;
        BitMaps.BitMap userReceiveMusicbox;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _initialOwner,
        IERC721 _blueboxAddr,
        IERC721 _musicboxAddr,
        bytes32 _blueboxRoot,
        bytes32 _musicboxRoot
    ) public initializer {
        RewardDistributionStorage storage $ = _getRewardDistributionStorage();

        $.blueboxAddr = _blueboxAddr;
        $.musicboxAddr = _musicboxAddr;
        $.blueboxRoot = _blueboxRoot;
        $.musicboxRoot = _musicboxRoot;

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
     * @param merkleRootOpt 0 is blueboxRoot else is musicboxRoot
     * @param merkleRoot Merkle root data
     */
    function updateMerkleRoot(uint256 merkleRootOpt, bytes32 merkleRoot) external onlyOwner {
        RewardDistributionStorage storage $ = _getRewardDistributionStorage();

        if (merkleRootOpt == 0) {
            $.blueboxRoot = merkleRoot;
        } else {
            $.musicboxRoot = merkleRoot;
        }

        emit SetMerkleRootInformation(merkleRootOpt, merkleRoot);
    }

    /**
     * @dev Update token address only owner
     * @param erc721TokenOpt 0 is bluebox else is musicbox
     * @param newTokenAddress New token address
     */
    function updateTokenAddress(uint256 erc721TokenOpt, IERC721 newTokenAddress) external onlyOwner {
        RewardDistributionStorage storage $ = _getRewardDistributionStorage();

        if (erc721TokenOpt == 0) {
            $.blueboxAddr = newTokenAddress;
        } else {
            $.musicboxAddr = newTokenAddress;
        }

        emit SetTokenAddress(erc721TokenOpt, address(newTokenAddress));
    }

    /**
     * @dev Owner withdraw NFTs
     * @param opt 0 is bluebox else is musicbox
     * @param nftTokenIds Withdraw NFT id list
     * @param recipientAddr Recipient address
     */
    function withdrawNfts(uint256 opt, uint256[] calldata nftTokenIds, address recipientAddr) external onlyOwner {
        RewardDistributionStorage storage $ = _getRewardDistributionStorage();

        IERC721 transferNFT = opt == 0 ? $.blueboxAddr : $.musicboxAddr;

        for (uint256 i; i < nftTokenIds.length; ) {
            uint256 nftTokenId = nftTokenIds[i];
            transferNFT.safeTransferFrom(address(this), recipientAddr, nftTokenId);
            unchecked {
                ++i;
            }
        }

        emit OwnerWithdraw(address(transferNFT), nftTokenIds, recipientAddr);
    }

    /**
     * @dev Check whether the user has received the token represented by opt
     * @param userAddresss User address
     * @param opt 0 is bluebox else is musicbox
     */
    function isClaimed(address userAddresss, uint256 opt) public view returns (bool) {
        RewardDistributionStorage storage $ = _getRewardDistributionStorage();

        return
            opt == 0
                ? $.userReceiveBluebox.get(uint256(uint160(userAddresss)))
                : $.userReceiveMusicbox.get(uint256(uint160(userAddresss)));
    }

    /**
     * @dev Claim NFT
     * @param opt 0 is bluebox else is musicbox
     * @param tokenIds  Array of NFT IDs to be collected
     * @param merkleProof Merkle proof
     */
    function claim(uint256 opt, uint256[] calldata tokenIds, bytes32[] calldata merkleProof) external nonReentrant {
        RewardDistributionStorage storage $ = _getRewardDistributionStorage();

        if (isClaimed(msg.sender, opt)) revert AlreadyReceived();

        // Verify the merkle proof.
        bytes32 NFTMerkleRoot = opt == 0 ? $.blueboxRoot : $.musicboxRoot;
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, tokenIds));
        if (!MerkleProof.verify(merkleProof, NFTMerkleRoot, leaf)) revert VerificationFailed();

        // Update user receive
        opt == 0
            ? $.userReceiveBluebox.setTo(uint256(uint160(msg.sender)), true)
            : $.userReceiveMusicbox.setTo(uint256(uint160(msg.sender)), true);

        // Transfer NFT
        IERC721 transferNFT = opt == 0 ? $.blueboxAddr : $.musicboxAddr;
        for (uint256 i; i < tokenIds.length; ) {
            transferNFT.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
            unchecked {
                ++i;
            }
        }

        emit Claimed(msg.sender, tokenIds);
    }

    function _getRewardDistributionStorage() private pure returns (RewardDistributionStorage storage $) {
        assembly {
            $.slot := RewardDistributionStorageLocation
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
