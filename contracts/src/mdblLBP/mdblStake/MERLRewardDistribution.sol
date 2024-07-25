// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable, Initializable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ERC20PermitUpgradeable, ECDSA} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";

contract MERLRewardDistribution is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable
{
    error NotEnoughAvailableAmount();
    event PermitTransfer(address to, uint256 value);

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant EMDBL_ROLE = keccak256("EMDBL_ROLE");

    // keccak256(abi.encode(uint256(keccak256("MERLRewardDistributionStorage")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant MERLRewardDistributionStorageLocation =
        0xe2a8617dc5cc786fa43addf5688414422a578667dae166c7c0d47f7d4ec9d200;

    bytes32 private constant PERMIT_TRANSFERHASH =
        keccak256("PermitTransfer(address to,uint256 value,uint256 nonce,uint256 deadline)");
    // 0x49b50beecd84b7d5820d0b061b6f847e7c1f55dd18d8485b2d478a4b9a361cf6

    struct MERLRewardDistributionStorage {
        address signer;
        IERC20 MERLAddress;
        mapping(address => uint256) userHasUsedPermitQuota;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address defaultAdmin, IERC20 MERLAddress, address signer) public initializer {
        MERLRewardDistributionStorage storage $ = _getMERLRewardDistributionStorage();

        $.signer = signer;
        $.MERLAddress = MERLAddress;

        __AccessControl_init();
        __UUPSUpgradeable_init();
        __ERC20Permit_init("MERLRewardDistribution");

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(PAUSER_ROLE, defaultAdmin);
        _grantRole(UPGRADER_ROLE, defaultAdmin);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setSigner(address newSigner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        MERLRewardDistributionStorage storage $ = _getMERLRewardDistributionStorage();

        $.signer = newSigner;
    }

    function setTokenAddress(IERC20 newMERLAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        MERLRewardDistributionStorage storage $ = _getMERLRewardDistributionStorage();

        $.MERLAddress = newMERLAddress;
    }

    function transferMERL(address to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        MERLRewardDistributionStorage storage $ = _getMERLRewardDistributionStorage();

        $.MERLAddress.transfer(to, amount);
    }

    function permitTransfer(address to, uint256 totalAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        MERLRewardDistributionStorage storage $ = _getMERLRewardDistributionStorage();

        if (block.timestamp > deadline) revert ERC2612ExpiredSignature(deadline);

        bytes32 structHash = keccak256(abi.encode(PERMIT_TRANSFERHASH, to, totalAmount, _useNonce(to), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != $.signer) revert ERC2612InvalidSigner(signer, $.signer);

        uint256 hasUsedPermitQuota = $.userHasUsedPermitQuota[to];
        $.userHasUsedPermitQuota[to] = totalAmount;
        uint256 remainingAmount = totalAmount - hasUsedPermitQuota;

        if ($.MERLAddress.balanceOf(address(this)) < remainingAmount) revert NotEnoughAvailableAmount();
        $.MERLAddress.transfer(to, remainingAmount);

        emit PermitTransfer(to, remainingAmount);
    }

    function getUserRewardsReceived(address account) external view returns (uint256) {
        MERLRewardDistributionStorage storage $ = _getMERLRewardDistributionStorage();

        return $.userHasUsedPermitQuota[account];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function _getMERLRewardDistributionStorage() private pure returns (MERLRewardDistributionStorage storage $) {
        assembly {
            $.slot := MERLRewardDistributionStorageLocation
        }
    }
}
