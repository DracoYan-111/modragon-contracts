// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {IERC721Enumerable, IERC721} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {UUPSUpgradeable, Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {IBatchBurnERC721, IeMDBL} from "./interfaces/IBatchBurnERC721.sol";

contract BatchBurnERC721 is
    Initializable,
    UUPSUpgradeable,
    Ownable2StepUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IBatchBurnERC721
{
    using MerkleProof for bytes32;
    using BitMaps for BitMaps.BitMap;

    uint256 private constant WAD = 1 ether;
    // keccak256(abi.encode(uint256(keccak256("BatchBurnERC721Storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant BatchBurnERC721StorageLocation =
        0x873ce42bb11da2a877551a94a0d3c475f2712498a6c230654f29ac5df3ca2400;

    struct BatchBurnERC721Storage {
        bool receiveOpen;
        bytes32 receiveRoot;
        IeMDBL eMDBLAddress;
        IERC20 MERLAddress;
        IERC721 erc721Address;
        uint256 totalBurnAmount;
        // Total number of rewards
        uint256 totaleMDBLReward;
        // =======================
        BitMaps.BitMap userReceiveMERL;
        BitMaps.BitMap userReceiveeMDBL;
        mapping(address => uint256[]) userBurnIndex;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner_, IERC721 erc721Address_, uint256 totaleMDBLReward_) public initializer {
        BatchBurnERC721Storage storage $ = _getBatchBurnERC721Storage();

        $.erc721Address = erc721Address_;
        $.totaleMDBLReward = totaleMDBLReward_;

        __Pausable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __Ownable_init(initialOwner_);
    }

    function _getBatchBurnERC721Storage() private pure returns (BatchBurnERC721Storage storage $) {
        assembly {
            $.slot := BatchBurnERC721StorageLocation
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setReceiveRoot(bytes32 newReceiveRoot) external onlyOwner {
        BatchBurnERC721Storage storage $ = _getBatchBurnERC721Storage();

        $.receiveRoot = newReceiveRoot;
    }

    function setTokenAddress(uint256 opt, address newTokenAddress) external onlyOwner {
        BatchBurnERC721Storage storage $ = _getBatchBurnERC721Storage();

        if (opt == 0) {
            $.eMDBLAddress = IeMDBL(newTokenAddress);
        } else {
            $.MERLAddress = IERC20(newTokenAddress);
        }
    }

    function setErc721Address(IERC721 newErc721Address) external onlyOwner {
        BatchBurnERC721Storage storage $ = _getBatchBurnERC721Storage();
        
        $.erc721Address = newErc721Address;
    }

    function setTokenReward(uint256 newTokenReward) external onlyOwner {
        BatchBurnERC721Storage storage $ = _getBatchBurnERC721Storage();

        $.totaleMDBLReward = newTokenReward;
    }

    function setReceiveOpen() external onlyOwner {
        BatchBurnERC721Storage storage $ = _getBatchBurnERC721Storage();

        $.receiveOpen = true;
    }

    /**
     * @dev User burn token
     * @param tokenIds User burn token id list
     */
    function batchBurn(uint256[] calldata tokenIds) external nonReentrant whenNotPaused {
        BatchBurnERC721Storage storage $ = _getBatchBurnERC721Storage();

        if ($.receiveOpen) revert RewardsAreOpen();

        for (uint256 i = 0; i < tokenIds.length; ) {
            if (
                $.erc721Address.getApproved(tokenIds[i]) != address(this) &&
                !$.erc721Address.isApprovedForAll($.erc721Address.ownerOf(tokenIds[i]), address(this))
            ) revert ContractNotAuthorizedToBurn();

            if ($.erc721Address.ownerOf(tokenIds[i]) != msg.sender) revert CallerNotTheTokenOwner();
            $.userBurnIndex[msg.sender].push(tokenIds[i]);

            $.erc721Address.transferFrom(msg.sender, address(9), tokenIds[i]);

            unchecked {
                ++i;
            }
        }
        $.totalBurnAmount += tokenIds.length;

        emit UserBurn(msg.sender, tokenIds);
    }

    /**
     * @dev Claim eMDBL
     */
    function usersReceiveeMDBLRewards() external whenNotPaused {
        BatchBurnERC721Storage storage $ = _getBatchBurnERC721Storage();

        if (!$.receiveOpen) revert RewardsAreNotOpen();

        if (isClaimed(msg.sender, 0)) revert AlreadyReceived();

        $.userReceiveeMDBL.set(uint160(msg.sender));

        (, , , , uint256 userRewards) = getUsereMDBLRewardData(msg.sender);
        $.eMDBLAddress.mint(msg.sender, userRewards);

        emit UsersReceiveeMDBLRewards(msg.sender, userRewards);
    }

    /**
     * @dev Claim MERL
     * @param index Index corresponding to user address
     * @param amount  Token amount
     * @param merkleProof Merkle proof
     */
    function usersReceiveMERLRewards(
        uint256 index,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external whenNotPaused {
        BatchBurnERC721Storage storage $ = _getBatchBurnERC721Storage();

        if (!$.receiveOpen) revert RewardsAreNotOpen();

        if (isClaimed(msg.sender, 1)) revert AlreadyReceived();

        // Verify the merkle proof.
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(index, msg.sender, amount))));
        if (!MerkleProof.verify(merkleProof, $.receiveRoot, leaf)) revert VerificationFailed();

        $.userReceiveMERL.set(uint160(msg.sender));
        $.MERLAddress.transfer(msg.sender, amount);

        emit UsersReceiveMERLRewards(msg.sender, amount);
    }

    /**
     * @dev Check whether the index corresponding to the user is used
     * @param userAddress User address
     * @param opt 0: eMDBL, 1: MERL
     */
    function isClaimed(address userAddress, uint256 opt) public view returns (bool) {
        BatchBurnERC721Storage storage $ = _getBatchBurnERC721Storage();

        return opt == 0 ? $.userReceiveeMDBL.get(uint160(userAddress)) : $.userReceiveMERL.get(uint160(userAddress));
    }

    /**
     * @dev Get the number of user burn NFT
     * @param userAddress User address
     * @return User burn token amount
     */
    function getUserBurnLength(address userAddress) public view returns (uint256) {
        BatchBurnERC721Storage storage $ = _getBatchBurnERC721Storage();

        return $.userBurnIndex[userAddress].length;
    }

    /**
     * @dev Get the number of user eMDBL rewards
     * @param userAddress User address
     * @return Total eMDBL rewards amount
     *         User burn token amount
     *         Total burn token amount
     *         User burn token share
     *         User eMDBL rewards
     */
    function getUsereMDBLRewardData(
        address userAddress
    ) public view returns (uint256, uint256, uint256, uint256, uint256) {
        BatchBurnERC721Storage storage $ = _getBatchBurnERC721Storage();

        uint256 userShare = divWad(getUserBurnLength(userAddress), getTotalBurnAmount());

        return (
            $.totaleMDBLReward,
            getUserBurnLength(userAddress),
            getTotalBurnAmount(),
            userShare,
            mulWad(userShare, $.totaleMDBLReward)
        );
    }

    /**
     * @dev Get the number of burn NFT for all users
     */
    function getTotalBurnAmount() public view returns (uint256) {
        BatchBurnERC721Storage storage $ = _getBatchBurnERC721Storage();

        return $.totalBurnAmount;
    }

    /**
     * @dev Check whether reward collection is enabled
     * @return Whether reward collection is enabled
     */
    function getReceiveOpen() public view returns (bool) {
        BatchBurnERC721Storage storage $ = _getBatchBurnERC721Storage();

        return $.receiveOpen;
    }

    /**
     * @dev Get user tokenID list
     * @param userAddress User address
     * @return User tokenID list
     */
    function getUserTokenIdList(address userAddress) public view returns (uint256[] memory) {
        BatchBurnERC721Storage storage $ = _getBatchBurnERC721Storage();

        uint256 userBalance = $.erc721Address.balanceOf(userAddress);

        uint256[] memory tokenIdList = new uint256[](userBalance);

        for (uint256 i; i < userBalance; ) {
            tokenIdList[i] = (IERC721Enumerable(address($.erc721Address)).tokenOfOwnerByIndex(userAddress, i));

            unchecked {
                ++i;
            }
        }

        return tokenIdList;
    }

    /**
     * @dev Equivalent to `(x * y) / WAD` rounded down.
     **/
    function mulWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                mstore(0x00, 0xbac65e5b) // `MulWadFailed()`.
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), WAD)
        }
    }

    /**
     * @dev Equivalent to `(x * WAD) / y` rounded down.
     **/
    function divWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                mstore(0x00, 0x7c5f487d) // `DivWadFailed()`.
                revert(0x1c, 0x04)
            }
            z := div(mul(x, WAD), y)
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
