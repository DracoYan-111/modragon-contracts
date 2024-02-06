// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {ReentrancyGuardUpgradeable, Initializable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {IMerlinchainDBALRewards} from "./interfaces/IMerlinchainDBALRewards.sol";

contract MerlinchainDBALRewards is
    Initializable,
    UUPSUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    Ownable2StepUpgradeable,
    IMerlinchainDBALRewards
{
    using SafeERC20 for IERC20;
    using MerkleProof for bytes32;
    using BitMaps for BitMaps.BitMap;

    // keccak256(abi.encode(uint256(keccak256("MerlinchainDBALRewardsStorage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant MerlinchainDBALRewardsStorageLocation =
        0x1cb846c39391c7c85de0ae4824d008834c775192b6ed886f0217e32196ca1700;

    struct MerlinchainDBALRewardsStorage {
        IERC20 DBALAddress;
        IERC20 MUSDTAddress;
        uint128 MBTCQuantityCharged;
        uint128 MUSDTQuantityCharged;
        bytes32 _DBALMerkleRoot;
        bytes32 _refundMerkleRoot;
        // The default value is 9000,9 is a placeholder
        // The hundreds digit is the mint method status,
        // The tenth digit is the status of the DBAL collection method.
        // Single digit is the status of refund collection method.
        // 0: off 1: on
        uint256 mintDbalRefundStatus;
        BitMaps.BitMap userReceiveDBAL;
        BitMaps.BitMap userReceiveRefund;
        mapping(address => uint256) userMintNumber;
        mapping(uint256 => uint256) claimedMBTCBitMap;
        mapping(uint256 => uint256) claimedMUSDTBitMap;
        mapping(address => uint256) userPaysMBTCNumber;
        mapping(address => uint256) userPaysMUSDTNumber;
    }

    modifier onlyMintOpen() {
        (bool mintStatus, , ) = extractStatus();
        if (!mintStatus) revert EventIsClosed();
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _initialOwner,
        IERC20 _MUSDTAddress,
        uint128 _MBTCQuantityCharged,
        uint128 _MUSDTQuantityCharged
    ) public initializer {
        MerlinchainDBALRewardsStorage storage $ = _getMerlinchainDBALRewardsStorage();

        $.MUSDTAddress = _MUSDTAddress;
        $.MBTCQuantityCharged = _MBTCQuantityCharged;
        $.MUSDTQuantityCharged = _MUSDTQuantityCharged;
        // The default value is 9000,
        // 9 is a placeholder
        // 1 is mint function on
        $.mintDbalRefundStatus = 9100;

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
     * @param merkleRootNumber 1 is _DBALMerkleRoot 2 is _refundMerkleRoot
     * @param merkleRoot Merkle root data
     */
    function updateMerkleRoot(uint256 merkleRootNumber, bytes32 merkleRoot) external onlyOwner {
        MerlinchainDBALRewardsStorage storage $ = _getMerlinchainDBALRewardsStorage();

        if (merkleRootNumber == 1) {
            $._DBALMerkleRoot = merkleRoot;
        } else {
            $._refundMerkleRoot = merkleRoot;
        }

        emit SetMerkleRootInformation(merkleRootNumber, merkleRoot);
    }

    /**
     * @dev Update token address only owner
     * @param erc20TokenNumber 1 is DBAL 2 is MUSDT
     * @param newTokenAddress New token address
     */
    function updateTokenAddress(uint256 erc20TokenNumber, IERC20 newTokenAddress) external onlyOwner {
        MerlinchainDBALRewardsStorage storage $ = _getMerlinchainDBALRewardsStorage();

        if (erc20TokenNumber == 1) {
            $.DBALAddress = newTokenAddress;
        } else {
            $.MUSDTAddress = newTokenAddress;
        }

        emit SetTokenAddress(erc20TokenNumber, address(newTokenAddress));
    }

    /**
     * @dev User mint
     * @param mintAmount Mint quantity
     * @param tokenAddress Pay token address(address(0) is MBTC else MUSDT)
     */
    function mint(uint256 mintAmount, IERC20 tokenAddress) external payable onlyMintOpen nonReentrant {
        MerlinchainDBALRewardsStorage storage $ = _getMerlinchainDBALRewardsStorage();

        uint256 paymentAmount;

        if (address(tokenAddress) == address(0)) {
            (paymentAmount, ) = getQuantityCharged(mintAmount);

            if (msg.value != paymentAmount) revert IncorrectMintQuantity();

            $.userPaysMBTCNumber[msg.sender] += paymentAmount;
        } else {
            (, paymentAmount) = getQuantityCharged(mintAmount);

            $.MUSDTAddress.safeTransferFrom(msg.sender, address(this), paymentAmount);
        }
        $.userMintNumber[msg.sender] += mintAmount;

        emit UserMint(mintAmount, paymentAmount, address(tokenAddress));
    }

    function receiveDbalToken(uint256, uint256, bytes32[] calldata) external nonReentrant {
        emit UserHasReceivedDBAL();
    }

    function receiveRefundToken(uint256, uint256, bytes32[] calldata) external nonReentrant {
        emit UserHasReceivedRefund();
    }

    /**
     * @dev Check if the user has claimed
     * @param index Index in merkle tree
     * @param functionIndex 1 for MBTC else for MUSDT
     */
    function isClaimed(uint256 index, uint256 functionIndex) public view returns (bool) {
        MerlinchainDBALRewardsStorage storage $ = _getMerlinchainDBALRewardsStorage();

        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;

        uint256 claimedWord = functionIndex == 1
            ? $.claimedMBTCBitMap[claimedWordIndex]
            : $.claimedMUSDTBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);

        return (claimedWord & mask == mask);
    }

    /**
     * @dev Get the sum of mint
     * @param userAddress User address
     * @return User address the sum of mint
     */
    function getUserMintNumber(address userAddress) external view returns (uint256) {
        MerlinchainDBALRewardsStorage storage $ = _getMerlinchainDBALRewardsStorage();

        return $.userMintNumber[userAddress];
    }

    /**
     * @dev Get pay the number of MBTC and MUSDT
     * @param mintAmount Mint amount
     * @return Pay MBTC total number
     * @return Pay MUSDT total number
     */
    function getQuantityCharged(uint256 mintAmount) public view returns (uint256, uint256) {
        if (mintAmount == 0) revert IncorrectMintAmount();

        MerlinchainDBALRewardsStorage storage $ = _getMerlinchainDBALRewardsStorage();

        return (mintAmount * $.MBTCQuantityCharged, mintAmount * $.MUSDTQuantityCharged);
    }

    /**
     * @dev Get the token address
     * @return DBAL token address
     * @return MUSDT token address
     */
    function getTokenAddress() external view returns (IERC20, IERC20) {
        MerlinchainDBALRewardsStorage storage $ = _getMerlinchainDBALRewardsStorage();

        return ($.DBALAddress, $.MUSDTAddress);
    }

    /**
     * @dev Get user address the number of MBTC and MUSDT
     * @param userAddress Check user address
     * @return User pay MBTC total number
     * @return User pay MUSDT total number
     */
    function getUserPayTokenDetails(address userAddress) external view returns (uint256, uint256) {
        MerlinchainDBALRewardsStorage storage $ = _getMerlinchainDBALRewardsStorage();

        return ($.userPaysMBTCNumber[userAddress], $.userPaysMUSDTNumber[userAddress]);
    }

    /**
     * @dev Get the status of function
     * @return mintStatus Mint function off or on
     * @return dbalStatus DBAL function off or on
     * @return refundStatus Refund function off or on
     */
    function extractStatus() public view returns (bool mintStatus, bool dbalStatus, bool refundStatus) {
        MerlinchainDBALRewardsStorage storage $ = _getMerlinchainDBALRewardsStorage();

        // The default value is 9000
        // 9 is a placeholder
        // The hundreds digit is the mint method status,
        mintStatus = (($.mintDbalRefundStatus / 100) % 10) > 0;

        // The tenth digit is the status of the DBAL collection method.
        dbalStatus = (($.mintDbalRefundStatus / 10) % 10) > 0;

        // Single digit is the status of refund collection method.
        refundStatus = ($.mintDbalRefundStatus % 10) > 0;
    }

    /**
     * @dev Set the status of collection token
     * @param index Index in merkle tree
     * @param functionIndex 1 for MBTC else for MUSDT
     */
    function _setClaimed(uint256 index, uint256 functionIndex) private {
        MerlinchainDBALRewardsStorage storage $ = _getMerlinchainDBALRewardsStorage();

        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;

        if (functionIndex == 1) {
            $.claimedMBTCBitMap[claimedWordIndex] = $.claimedMBTCBitMap[claimedWordIndex] | (1 << claimedBitIndex);
        } else {
            $.claimedMUSDTBitMap[claimedWordIndex] = $.claimedMUSDTBitMap[claimedWordIndex] | (1 << claimedBitIndex);
        }
    }

    function _getMerlinchainDBALRewardsStorage() private pure returns (MerlinchainDBALRewardsStorage storage $) {
        assembly {
            $.slot := MerlinchainDBALRewardsStorageLocation
        }
    }

    function _callSendMBTC(address userAddress, uint256 amount) private {
        if (amount > address(this).balance) revert InsufficientMBTCBalance();

        (bool sent, ) = payable(userAddress).call{value: amount}("");

        if (!sent) revert MBTCTransferFailed();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
