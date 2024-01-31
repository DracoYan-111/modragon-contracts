// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MantaRewardDistribution {
    using SafeERC20 for IERC20;

    error QuantityDoesNotMatch();

    event rewardDistribution(uint256 numberOfPeople);

    function issueInBatches(
        IERC20 tokenAddress,
        uint256[] calldata rewardList,
        address[] calldata userAddrList
    ) external {
        uint256 userAddrListLength = userAddrList.length;
        uint256 rewardListLength = rewardList.length;

        if (userAddrListLength != rewardListLength) revert QuantityDoesNotMatch();

        for (uint256 i = 0; i < userAddrListLength; ) {
            tokenAddress.safeTransferFrom(msg.sender, userAddrList[i], rewardList[i]);
            unchecked {
                ++i;
            }
        }

        emit rewardDistribution(userAddrListLength);
    }
}