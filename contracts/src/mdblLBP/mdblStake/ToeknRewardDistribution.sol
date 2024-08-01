// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable, Initializable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ERC20PermitUpgradeable, ECDSA} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";

contract ToeknRewardDistribution is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable
{
    error NotEnoughAvailableAmount();
    event PermitTransfer(address tokenAddress, address to, uint256 value);

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant EMDBL_ROLE = keccak256("EMDBL_ROLE");

    // keccak256(abi.encode(uint256(keccak256("ToeknRewardDistributionStorage")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant ToeknRewardDistributionStorageLocation =
        0x35d836399424e465e95ce0b4bc99fe364a4955e1066b31bc62740f5d5cd98600;

    bytes32 private constant PERMIT_TRANSFERHASH =
        keccak256("PermitTransfer(address tokenAddress,address to,uint256 value,uint256 nonce,uint256 deadline)");
    // 0x3c73f60eb5427d2ad7bf6bde65f1067a6f1311fa0add9ba4171bf344253cccba

    struct ToeknRewardDistributionStorage {
        address signer;
        mapping(IERC20 => mapping(address => uint256)) userHasUsedTokenPermitQuota;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address defaultAdmin, address signer) public initializer {
        ToeknRewardDistributionStorage storage $ = _getTokenRewardDistributionStorage();

        $.signer = signer;

        __AccessControl_init();
        __UUPSUpgradeable_init();
        __ERC20Permit_init("ToeknRewardDistribution");

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
        ToeknRewardDistributionStorage storage $ = _getTokenRewardDistributionStorage();

        $.signer = newSigner;
    }

    function transferToken(IERC20 tokenAddress, address to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenAddress.transfer(to, amount);
    }

    function permitTransfer(
        IERC20 tokenAddress,
        address to,
        uint256 totalAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        ToeknRewardDistributionStorage storage $ = _getTokenRewardDistributionStorage();

        if (block.timestamp > deadline) revert ERC2612ExpiredSignature(deadline);

        bytes32 structHash = keccak256(
            abi.encode(PERMIT_TRANSFERHASH, tokenAddress, to, totalAmount, _useNonce(to), deadline)
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != $.signer) revert ERC2612InvalidSigner(signer, $.signer);

        uint256 hasUsedPermitQuota = $.userHasUsedTokenPermitQuota[tokenAddress][to];
        $.userHasUsedTokenPermitQuota[tokenAddress][to] = totalAmount;
        uint256 remainingAmount = totalAmount - hasUsedPermitQuota;

        if (tokenAddress.balanceOf(address(this)) < remainingAmount) revert NotEnoughAvailableAmount();
        tokenAddress.transfer(to, remainingAmount);

        emit PermitTransfer(address(tokenAddress), to, remainingAmount);
    }

    function getUserTokenRewardsReceived(IERC20 tokenAddress, address account) external view returns (uint256) {
        ToeknRewardDistributionStorage storage $ = _getTokenRewardDistributionStorage();

        return $.userHasUsedTokenPermitQuota[tokenAddress][account];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function _getTokenRewardDistributionStorage() private pure returns (ToeknRewardDistributionStorage storage $) {
        assembly {
            $.slot := ToeknRewardDistributionStorageLocation
        }
    }
}
