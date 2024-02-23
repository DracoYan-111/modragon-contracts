// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {UUPSUpgradeable, Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {IDragonBallHatch} from "./interfaces/IDragonBallHatch.sol";

contract DragonBallHatch is
    Initializable,
    Ownable2StepUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IDragonBallHatch
{
    using SafeERC20 for IERC20;

    // keccak256(abi.encode(uint256(keccak256("DragonBallHatchStorage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant DragonBallHatchStorageLocation =
        0x0b6987b389dcc0bfa1b2fd5e8cd837cabe6b24bd967d0f608ff413941eab9e00;

    struct DragonBallHatchStorage {
        mapping(IERC20 => uint256) tokenAmount;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __Pausable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __Ownable_init(initialOwner);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Owner withdraw tokens
     * @param tokenAddress Token address(address(0) is BTC)
     * @param tokenAmount Withdraw token amount
     * @param recipientAddr Recipient address
     */
    function withdrawFunds(IERC20 tokenAddress, uint256 tokenAmount, address recipientAddr) external onlyOwner {
        DragonBallHatchStorage storage $ = _geDragonBallHatchStorage();

        $.tokenAmount[tokenAddress] -= tokenAmount;

        if (address(tokenAddress) == address(0)) {
            _callSendBTC(recipientAddr, tokenAmount);
        } else {
            tokenAddress.safeTransfer(recipientAddr, tokenAmount);
        }

        emit OwnerWithdraw(address(tokenAddress), tokenAmount, recipientAddr);
    }

    /**
     * @dev User uses correct bizId hatch balls
     * @param bizId User's correct bizId
     * @param paymentToken Token address(address(0) is BTC)
     * @param paymentAmount Payment token amount
     */
    function hatchBalls(
        string calldata bizId,
        IERC20 paymentToken,
        uint256 paymentAmount
    ) external payable nonReentrant whenNotPaused {
        DragonBallHatchStorage storage $ = _geDragonBallHatchStorage();

        if (address(paymentToken) == address(0)) {
            if (msg.value != paymentAmount) revert BTCPaymentFailed();
        } else {
            paymentToken.safeTransferFrom(msg.sender, address(this), paymentAmount);
        }

        $.tokenAmount[paymentToken] += paymentAmount;

        emit UserHatching(bizId, address(paymentToken), paymentAmount, msg.sender);
    }

    /**
     * @dev Get tokens amount
     * @param paymentToken Token address
     */
    function getTokenAmount(IERC20 paymentToken) external view returns (uint256) {
        DragonBallHatchStorage storage $ = _geDragonBallHatchStorage();

        return $.tokenAmount[paymentToken];
    }

    function _geDragonBallHatchStorage() private pure returns (DragonBallHatchStorage storage $) {
        assembly {
            $.slot := DragonBallHatchStorageLocation
        }
    }

    function _callSendBTC(address userAddress, uint256 amount) private {
        if (amount > address(this).balance) revert InsufficientBTCBalance();

        (bool sent, ) = payable(userAddress).call{value: amount}("");

        if (!sent) revert BTCTransferFailed();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
