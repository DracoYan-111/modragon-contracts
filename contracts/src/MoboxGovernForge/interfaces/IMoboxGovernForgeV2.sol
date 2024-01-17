// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IMoboxGovernForgeV2Def {

    /**
     * @dev Check the number of destructions entered by the user to prevent more destructions
     */
    error CheckLimitExceededFailed();

    event SetBurnAmount(uint256 indexed newBurnAmout, uint256 oldBurnAmout);
    event UserBurned(address indexed userAddress, uint256 indexed totalNumberBurn, uint256 burnAmount);

}

interface IMoboxGovernForgeV2 is IMoboxGovernForgeV2Def{}