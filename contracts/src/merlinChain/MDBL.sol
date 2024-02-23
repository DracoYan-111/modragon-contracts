// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC20, ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract MDBL is ERC20, ERC20Burnable {
    constructor(
        address fairLaunchTreasury,
        address gameOutputTreasury,
        address initialLiquidityTreasury
    ) ERC20("MDBL", "MDBL") {
        uint256 total = 2100000000 * 1 ether;
        uint256 fairLaunch = (total * 69) / 100;
        uint256 gameOutput = (total * 30) / 100;
        uint256 initialLiquidity = (total * 1) / 100;
        _mint(fairLaunchTreasury, fairLaunch);
        _mint(gameOutputTreasury, gameOutput);
        _mint(initialLiquidityTreasury, initialLiquidity);
    }
}
