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

    event SetBurnAmount(uint256 indexed newBurnAmout, uint256 oldBurnAmout);
    event UserBurned(address indexed userAddress, uint256 indexed totalNumberBurn, uint256 burnAmount);

    uint256 public burnAmount;
    mapping(address => uint256) public userBurnCount;

    IERC20 public immutable moboxTokenAddress;
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
        emit SetBurnAmount(newBurnAmount, oldBurnAmount);
    }

    /**
     * @notice Burn tokens to gain the opportunity to send proposals
     * @dev Check the number of times destroyed
     * @param burnCount Number of times destroyed
     */
    function burnTokenForPower(uint256 burnCount) public whenNotPaused {
        if (burnCount == 0 || burnCount > 5) revert CheckLimitExceededFailed();

        uint256 allBurnAmount = burnAmount * burnCount;
        moboxTokenAddress.safeTransferFrom(msg.sender, BSC_BURN_ADDRESS, allBurnAmount);

        userBurnCount[msg.sender] += burnCount;

        emit UserBurned(msg.sender, userBurnCount[msg.sender], allBurnAmount);
    }
}
