// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

import {IMoboxGovernForgeV2} from "./interfaces/IMoboxGovernForgeV2.sol";

contract MoboxGovernForgeV2 is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    IMoboxGovernForgeV2
{
    using SafeERC20 for IERC20;

    address public constant BSC_BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // keccak256(abi.encode(uint256(keccak256("moboxGovernForgeV2Storage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant moboxGovernForgeV2Storage =
        0x725dbf551322c2034cd267626ac37a17c96839b6a03df8d67933a3e614376f00;

    struct MoboxGovernForgeV2Storage {
        mapping(address => uint256) userBurnCount;
        uint256 burnAmount;
        IERC20 moboxTokenAddress;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 burnAmount_, address initialOwner_, IERC20 moboxTokenAddress_) public initializer {
        MoboxGovernForgeV2Storage storage $ = _getMoboxGovernForgeV2Storage();

        $.burnAmount = burnAmount_;
        $.moboxTokenAddress = moboxTokenAddress_;

        __Ownable_init(initialOwner_);
        __UUPSUpgradeable_init();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Update burn amount
     * @param newBurnAmount New burn amount
     */
    function updateBurnAmount(uint256 newBurnAmount) external onlyOwner {
        MoboxGovernForgeV2Storage storage $ = _getMoboxGovernForgeV2Storage();
        uint256 oldBurnAmount = $.burnAmount;
        $.burnAmount = newBurnAmount;
        emit SetBurnAmount(newBurnAmount, oldBurnAmount);
    }

    /**
     * @notice Burn tokens to gain the opportunity to send proposals
     * @dev Check the number of times destroyed
     * @param burnCount Number of times destroyed
     */
    function burnForProposal(uint256 burnCount) public whenNotPaused {
        if (burnCount == 0 || burnCount > 5) revert CheckLimitExceededFailed();
        MoboxGovernForgeV2Storage storage $ = _getMoboxGovernForgeV2Storage();

        uint256 allBurnAmount = $.burnAmount * burnCount;
        $.moboxTokenAddress.safeTransferFrom(msg.sender, BSC_BURN_ADDRESS, allBurnAmount);

        uint256 totalNumberBurn = $.userBurnCount[msg.sender] += burnCount;

        emit UserBurned(msg.sender, totalNumberBurn, allBurnAmount);
    }

    function burnAmount() external view returns (uint256) {
        MoboxGovernForgeV2Storage storage $ = _getMoboxGovernForgeV2Storage();
        return $.burnAmount;
    }

    function userBurnCount(address userAddr) external view returns (uint256) {
        MoboxGovernForgeV2Storage storage $ = _getMoboxGovernForgeV2Storage();
        return $.userBurnCount[userAddr];
    }

    function _getMoboxGovernForgeV2Storage() private pure returns (MoboxGovernForgeV2Storage storage $) {
        assembly {
            $.slot := moboxGovernForgeV2Storage
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
