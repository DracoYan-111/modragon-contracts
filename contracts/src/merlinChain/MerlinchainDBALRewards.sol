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
        uint128 DBALQuantityCharged;
        IERC20 MUSDTAddress;
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

    function initialize(address _initialOwner) public initializer {
        MerlinchainDBALRewardsStorage storage $ = _getMerlinchainDBALRewardsStorage();

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

    function mint(uint256 mintAmount, IERC20 tokenAddress) external payable onlyMintOpen {
        MerlinchainDBALRewardsStorage storage $ = _getMerlinchainDBALRewardsStorage();
        uint256 paymentAmount;

        if (address(tokenAddress) == address(0)) {
            paymentAmount = mintAmount * $.DBALQuantityCharged;
            if (msg.value != paymentAmount) revert IncorrectMintAmount();
            $.userPaysMBTCNumber[msg.sender] += paymentAmount;
        } else {
            paymentAmount = mintAmount * $.MUSDTQuantityCharged;

            tokenAddress.safeTransferFrom(msg.sender, address(this), paymentAmount);
        }
        $.userMintNumber[msg.sender] += mintAmount;
        emit UserMint();
    }

    function receiveDbalToken(uint256 index, bytes32[] calldata proof) external {
        emit UserHasReceivedDBAL();
    }

    function receiveRefundToken(uint256 index, bytes32[] calldata proof) external {
        emit UserHasReceivedRefund();
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
