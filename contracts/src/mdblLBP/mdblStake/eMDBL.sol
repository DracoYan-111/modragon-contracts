// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC20BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {ERC20PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {ERC20Upgradeable,Initializable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract eMDBL is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20PausableUpgradeable,
    AccessControlUpgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    // keccak256(abi.encode(uint256(keccak256("EMDBLStorage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant EMDBLStorageLocation = 0x71dda1f6f2ed7a0e20080db1df0e8a7cf256427c18f1b5b746c4397b9165e600;

    struct EMDBLStorage {
        address[] transferWhitelist;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address defaultAdmin) public initializer {
        __ERC20_init("eMDBL", "eMDBL");
        __ERC20Burnable_init();
        __ERC20Pausable_init();
        __AccessControl_init();
        __ERC20Permit_init("eMDBL");
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(PAUSER_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, defaultAdmin);
        _grantRole(UPGRADER_ROLE, defaultAdmin);
        _grantRole(TRANSFER_ROLE, address(this));
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function permitMint(address owner, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        permit(owner, address(this), value, deadline, v, r, s);
        super._update(address(0), owner, value);
    }

    function batchAddTransferWhitelist(address[] calldata whitelist) external onlyRole(DEFAULT_ADMIN_ROLE) {
        EMDBLStorage storage $ = _getEMDBLStorage();

        for (uint256 i; i < whitelist.length; ) {
            $.transferWhitelist.push(whitelist[i]);
            _grantRole(TRANSFER_ROLE, whitelist[i]);

            unchecked {
                ++i;
            }
        }
    }

    function clearWhitelist() external onlyRole(DEFAULT_ADMIN_ROLE) {
        EMDBLStorage storage $ = _getEMDBLStorage();

        $.transferWhitelist = new address[](0);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function _getEMDBLStorage() private pure returns (EMDBLStorage storage $) {
        assembly {
            $.slot := EMDBLStorageLocation
        }
    }

    function getTransferWhitelist() external view returns (address[] memory) {
        EMDBLStorage storage $ = _getEMDBLStorage();

        return $.transferWhitelist;
    }

    // The following functions are overrides required by Solidity.

    function _grantRole(bytes32 role, address account) internal override returns (bool) {
        EMDBLStorage storage $ = _getEMDBLStorage();

        if (role == TRANSFER_ROLE) {
            $.transferWhitelist.push(account);
        }

        return super._grantRole(role, account);
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        EMDBLStorage storage $ = _getEMDBLStorage();

        if (!hasRole(MINTER_ROLE, msg.sender) && $.transferWhitelist.length > 0) {
            _checkRole(TRANSFER_ROLE);
        }

        super._update(from, to, value);
    }
}
