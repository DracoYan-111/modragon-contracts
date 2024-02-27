// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {UUPSUpgradeable, Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {IDragonBallBurn} from "./interfaces/IDragonBallBurn.sol";

contract DragonBallBurn is
    Initializable,
    UUPSUpgradeable,
    Ownable2StepUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IERC721Receiver,
    IDragonBallBurn
{
    // keccak256(abi.encode(uint256(keccak256("DragonBallBurnStorage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant DragonBallBurnStorageLocation =
        0x873ce42bb11da2a877551a94a0d3c475f2712498a6c230654f29ac5df3ca2400;

    struct DragonBallBurnStorage {
        uint128 checkChainId;
        IERC721 burnNFTAddress;
        uint256[] burnNftIds;
        uint256[] withdrawBurnNftIds;
        mapping(address => uint256) userReceivesAmount;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner_, IERC721 burnNFTAddress_, uint128 checkChainId_) public initializer {
        DragonBallBurnStorage storage $ = _getDragonBallBurnStorage();

        $.checkChainId = checkChainId_;
        $.burnNFTAddress = burnNFTAddress_;

        __Pausable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __Ownable_init(initialOwner_);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Owner update burn NFT address
     * @param newBurnNFTAddress New burn NFT address
     */
    function updateBurnNFTAddress(IERC721 newBurnNFTAddress) external onlyOwner {
        DragonBallBurnStorage storage $ = _getDragonBallBurnStorage();

        $.burnNFTAddress = newBurnNFTAddress;

        emit SetBurnNFTAddress(address(newBurnNFTAddress));
    }

    /**
     * @dev Owner update check chain id
     * @param newCheckChainId New check chain id
     */
    function updateCheckChainId(uint128 newCheckChainId) external onlyOwner {
        DragonBallBurnStorage storage $ = _getDragonBallBurnStorage();

        $.checkChainId = newCheckChainId;

        emit SetCheckChainId(newCheckChainId);
    }

    /**
     * @dev Owner withdraw NFTs
     * @param nftTokenIds Withdraw NFT id list
     * @param recipientAddr Recipient address
     */
    function withdrawNfts(uint256[] calldata nftTokenIds, address recipientAddr) external onlyOwner {
        DragonBallBurnStorage storage $ = _getDragonBallBurnStorage();

        for (uint256 i; i < nftTokenIds.length; ) {
            uint256 nftTokenId = nftTokenIds[i];
            $.burnNFTAddress.safeTransferFrom(address(this), recipientAddr, nftTokenId);

            $.withdrawBurnNftIds.push(nftTokenId);

            unchecked {
                ++i;
            }
        }

        emit OwnerWithdraw(address($.burnNFTAddress), nftTokenIds, recipientAddr);
    }

    /**
     * @dev Users destroy NFT in batches to obtain coupons
     * @param nftTokenIds TokenIds to be destroyed
     * @param targetAddress Receive target address
     */
    function burnNfGetCoupons(
        uint256[] calldata nftTokenIds,
        address targetAddress
    ) external nonReentrant whenNotPaused {
        DragonBallBurnStorage storage $ = _getDragonBallBurnStorage();

        if (block.chainid == $.checkChainId)
            if (msg.sender != targetAddress) revert ChainAddressCheckFailed();

        uint256 burnAmount = nftTokenIds.length;

        for (uint256 i; i < burnAmount; ) {
            uint256 nftTokenId = nftTokenIds[i];
            $.burnNFTAddress.safeTransferFrom(msg.sender, address(this), nftTokenId);

            $.burnNftIds.push(nftTokenId);

            unchecked {
                ++i;
            }
        }

        $.userReceivesAmount[targetAddress] += burnAmount;

        emit UserBurnNft(burnAmount, targetAddress);
    }

    /**
     * @dev Get user receives amount
     * @param userAddress User address
     */
    function getUserReceivesAmount(address userAddress) external view returns (uint256) {
        DragonBallBurnStorage storage $ = _getDragonBallBurnStorage();

        return $.userReceivesAmount[userAddress];
    }

    /**
     * @dev Get burn NFT id Array
     */
    function getBurnNftIds() external view returns (uint256[] memory) {
        DragonBallBurnStorage storage $ = _getDragonBallBurnStorage();

        return $.burnNftIds;
    }

    /**
     * @dev Get withdraw burn NFT id Array
     */
    function getWithdrawBurnNftIds() external view returns (uint256[] memory) {
        DragonBallBurnStorage storage $ = _getDragonBallBurnStorage();

        return $.withdrawBurnNftIds;
    }

    function _getDragonBallBurnStorage() private pure returns (DragonBallBurnStorage storage $) {
        assembly {
            $.slot := DragonBallBurnStorageLocation
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
