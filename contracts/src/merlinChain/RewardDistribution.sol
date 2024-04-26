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
        address blueboxOwner;
        address musicboxOwner;
        bytes32 receiveRoot;
        BitMaps.BitMap userReceive;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _initialOwner,
        IERC721 _blueboxAddr,
        IERC721 _musicboxAddr,
        address _blueboxOwner,
        address _musicboxOwner,
        bytes32 _receiveRoot
    ) public initializer {
        RewardDistributionStorage storage $ = _getRewardDistributionStorage();

        $.blueboxAddr = _blueboxAddr;
        $.musicboxAddr = _musicboxAddr;
        $.blueboxOwner = _blueboxOwner;
        $.musicboxOwner = _musicboxOwner;
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
     * @param newOwnerAddr Recipient address
     */
    function updateNftsOwner(uint256 opt, address newOwnerAddr) external onlyOwner {
        RewardDistributionStorage storage $ = _getRewardDistributionStorage();

        if (opt == 0) {
            $.blueboxOwner = newOwnerAddr;
        } else {
            $.musicboxOwner = newOwnerAddr;
        }
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
     * @param blueboxTokenIds  Array of NFT IDs to be collected
     * @param musicboxTokenIds  Array of NFT IDs to be collected
     * @param merkleProof Merkle proof
     */
    function claim(
        uint256 index,
        uint256[] calldata blueboxTokenIds,
        uint256[] calldata musicboxTokenIds,
        bytes32[] calldata merkleProof
    ) external nonReentrant whenNotPaused {
        RewardDistributionStorage storage $ = _getRewardDistributionStorage();

        if (isClaimed(index)) revert AlreadyReceived();

        // Verify the merkle proof.

        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(index, msg.sender, blueboxTokenIds, musicboxTokenIds)))
        );

        if (!MerkleProof.verify(merkleProof, $.receiveRoot, leaf)) revert VerificationFailed();

        // Update user receive
        $.userReceive.set(index);

        // Transfer NFT
        for (uint256 i; i < 2; ) {
            IERC721 transferNFT = i == 0 ? $.blueboxAddr : $.musicboxAddr;
            address ownerAddress = i == 0 ? $.blueboxOwner : $.musicboxOwner;
            uint256[] memory tokenIds = i == 0 ? blueboxTokenIds : musicboxTokenIds;

            for (uint256 j; j < tokenIds.length; ) {
                transferNFT.safeTransferFrom(ownerAddress, msg.sender, tokenIds[j]);
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
        
        emit Claimed(msg.sender, blueboxTokenIds, musicboxTokenIds);
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
