// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MoBoxTokenBurn is Ownable, Pausable {
    using SafeERC20 for IERC20;

    /**
     * @dev Check the number of destructions entered by the user to prevent more destructions
     */
    error CheckLimitExceededFailed();

    /**
     * @dev Check whether the initiating trader is consistent with the current caller to prevent contract calls
     */
    error CheckAddressValidityFailed(address txOrign);

    event SetBurnAmout(uint256 indexed newBurnAmout, uint256 oldBurnAmout);
    event SetMoboxToken(IERC20 indexed newMoboxToken, IERC20 indexed oldMoboxToken);
    event UserBurned(address indexed userAddress, uint256 indexed count, uint256 amount);

    uint256 public burnAmount;
    IERC20 public moboxTokenAddress;

    address public constant BSC_BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;


    constructor(uint256 burnAmount_, address initialOwner_, IERC20 moboxTokenAddress_) Ownable(initialOwner_) {
        burnAmount = burnAmount_;
        moboxTokenAddress = moboxTokenAddress_;
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
        uint256 oldBurnAmount = burnAmount;
        burnAmount = newBurnAmount;
        emit SetBurnAmout(newBurnAmount, oldBurnAmount);
    }

    /**
     * @dev Update mobox token address
     * @param newMoboxToken New mobox token address
     */
    function updateMoboxToken(IERC20 newMoboxToken) external onlyOwner {
        IERC20 oldMoboxToken = moboxTokenAddress;
        moboxTokenAddress = newMoboxToken;
        emit SetMoboxToken(newMoboxToken, oldMoboxToken);
    }

    /**
     * @notice Destroy mobox to obtain proposal opportunities
     * @dev Check that the caller is the user
     * @param count Number of count
     */
    function userBurnToken(uint256 count) public whenNotPaused {
        if (count > 0 && count <= 5) revert CheckLimitExceededFailed();
        if (msg.sender != tx.origin) revert CheckAddressValidityFailed(tx.origin);

        uint256 allBurnAmount = burnAmount * count;
        moboxTokenAddress.safeTransferFrom(msg.sender, BSC_BURN_ADDRESS, allBurnAmount);

        emit UserBurned(msg.sender, count, allBurnAmount);
    }
}
