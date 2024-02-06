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

    function updateMerkleRoot(uint256 merkleRootNumber, bytes32 merkleRoot) external onlyOwner {
        MerlinchainDBALRewardsStorage storage $ = _getMerlinchainDBALRewardsStorage();

        if (merkleRootNumber == 1) {
            $._DBALMerkleRoot = merkleRoot;
        } else {
            $._refundMerkleRoot = merkleRoot;
        }

        emit SetMerkleRootInformation(merkleRootNumber, merkleRoot);
    }

    function updateTokenAddress(IERC20 newDBALAddress, IERC20 newMUSDTAddress) external onlyOwner {
        MerlinchainDBALRewardsStorage storage $ = _getMerlinchainDBALRewardsStorage();
        if (address(newDBALAddress) != address(0)) {
            $.DBALAddress = newDBALAddress;

            emit SetTokenAddress(0, address(newDBALAddress));
        }

        if (address(newMUSDTAddress) != address(0)) {
            $.MUSDTAddress = newMUSDTAddress;

            emit SetTokenAddress(1, address(newMUSDTAddress));
        }
    }

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

    function isClaimed(uint256 index) public view returns (bool) {
        MerlinchainDBALRewardsStorage storage $ = _getMerlinchainDBALRewardsStorage();

        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = $.claimedMBTCBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);

        return claimedWord & mask == mask;
    }

    function getUserMintNumber(address userAddress) external view returns (uint256) {
        MerlinchainDBALRewardsStorage storage $ = _getMerlinchainDBALRewardsStorage();

        return $.userMintNumber[userAddress];
    }

    function getQuantityCharged(uint256 mintAmount) public view returns (uint256, uint256) {
        if (mintAmount == 0) revert IncorrectMintAmount();

        MerlinchainDBALRewardsStorage storage $ = _getMerlinchainDBALRewardsStorage();

        return (mintAmount * $.MBTCQuantityCharged, mintAmount * $.MUSDTQuantityCharged);
    }

    function getTokenAddress() external view returns (IERC20, IERC20) {
        MerlinchainDBALRewardsStorage storage $ = _getMerlinchainDBALRewardsStorage();

        return ($.DBALAddress, $.MUSDTAddress);
    }

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

    function _setClaimed(uint256 index) private {
        MerlinchainDBALRewardsStorage storage $ = _getMerlinchainDBALRewardsStorage();

        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        $.claimedMBTCBitMap[claimedWordIndex] = $.claimedMBTCBitMap[claimedWordIndex] | (1 << claimedBitIndex);
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
