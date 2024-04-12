// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC20BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {ERC20PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import {ERC20PermitUpgradeable, ECDSA} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {ERC20Upgradeable, Initializable, IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {FixedPointMathLib} from "solady/src/utils/FixedPointMathLib.sol";

import {IeMDBL} from "./interfaces/IeMDBL.sol";

contract eMDBL is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC20PausableUpgradeable,
    AccessControlUpgradeable,
    ERC20PermitUpgradeable,
    UUPSUpgradeable,
    IeMDBL
{
    uint256 private constant WAD = 1e18;
    uint256 public constant MAX_MINT_AMOUNT = 2100000000 ether;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address to,uint256 value,uint256 nonce,uint256 deadline)");

    // keccak256(abi.encode(uint256(keccak256("EMDBLStorage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant EMDBLStorageLocation = 0x71dda1f6f2ed7a0e20080db1df0e8a7cf256427c18f1b5b746c4397b9165e600;

    struct EMDBLStorage {
        address signer;
        IERC20 MDBLAddress;
        uint256 totalDeductedMDBL;
        address[] transferWhitelist;
        mapping(address => uint256) userQuantityInLock;
        mapping(address => RedemptionRequestExt[]) _extRedemptionRequests;
        mapping(address => uint256) userHasUsedPermitQuota;
        mapping(address => uint256) userSwapEMDBLIndex;
    }

    struct RedemptionRequestExt {
        uint256 amount;
        uint256 startTime;
        uint256 duration;
        uint256 endTime;
        bool completed;
        bool cancelled;
        uint256[5] __gap;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address _defaultAdmin, IERC20 _MDBLAddress, address _signer) public initializer {
        EMDBLStorage storage $ = _getEMDBLStorage();

        $.signer = _signer;
        $.MDBLAddress = _MDBLAddress;

        __ERC20_init("eMDBL", "eMDBL");
        __ERC20Burnable_init();
        __ERC20Pausable_init();
        __AccessControl_init();
        __ERC20Permit_init("eMDBL");
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        _grantRole(PAUSER_ROLE, _defaultAdmin);
        _grantRole(MINTER_ROLE, address(this));
        _grantRole(MINTER_ROLE, _defaultAdmin);
        _grantRole(UPGRADER_ROLE, _defaultAdmin);
        _grantRole(TRANSFER_ROLE, _defaultAdmin);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _checkAmountMint(to, amount);
    }

    function permitMint(address to, uint256 totalAmount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
        EMDBLStorage storage $ = _getEMDBLStorage();

        if (block.timestamp > deadline) revert ERC2612ExpiredSignature(deadline);

        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, to, totalAmount, _useNonce(to), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != $.signer) revert ERC2612InvalidSigner(signer, $.signer);

        uint256 hasUsedPermitQuota = $.userHasUsedPermitQuota[to];
        $.userHasUsedPermitQuota[to] = totalAmount;

        _checkAmountMint(to, totalAmount - hasUsedPermitQuota);

        emit PermitMintToken(to, totalAmount - hasUsedPermitQuota);
    }

    /**
     * @dev Function to add transfer whitelist addresses in batches.
     * @param whitelist Array of whitelist addresses to add.
     */
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

    /**
     * @dev Function clears whitelist addresses and opens transfer.
     */
    function clearWhitelist() external onlyRole(DEFAULT_ADMIN_ROLE) {
        EMDBLStorage storage $ = _getEMDBLStorage();

        $.transferWhitelist = new address[](0);
    }

    /**
     * @dev Function to obtain the MDBL that the user has abandoned.
     */
    function receiveDeductedMDBL(address recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        EMDBLStorage storage $ = _getEMDBLStorage();

        $.MDBLAddress.transfer(recipient, $.totalDeductedMDBL);
    }

    /**
     * @dev Function modifies existing singer.
     */
    function setSignerAddress(address newSigner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        EMDBLStorage storage $ = _getEMDBLStorage();

        $.signer = newSigner;

        emit UpdateSigner(newSigner);
    }

    /**
     * @dev Function to convert MDBL to eMDBL.
     * @param amount The amount of eMDBL to redeem.
     */
    function swapEMDBL(uint256 amount) external whenNotPaused {
        EMDBLStorage storage $ = _getEMDBLStorage();

        if (amount < 0.1 ether) revert InvalidAmount();

        $.MDBLAddress.transferFrom(msg.sender, address(this), amount);
        _checkAmountMint(msg.sender, amount);

        emit UserSwapEMDBL(msg.sender, amount, block.timestamp, ++$.userSwapEMDBLIndex[msg.sender]);
    }

    /**
     * @dev Function to start the redemption process.
     * @param amount The amount of MDBL to redeem.
     * @param duration The duration of the redemption process in seconds.
     */
    function startRedemption(uint256 amount, uint256 duration) public whenNotPaused {
        EMDBLStorage storage $ = _getEMDBLStorage();

        if (amount < 0.1 ether) revert InvalidAmount();
        if (getUserCanRedemptionBalance(msg.sender) < amount) revert NotEnoughAvailableAmount();
        if (duration != 15 days && duration != 30 days && duration != 90 days && duration != 180 days)
            revert InvalidDuration();

        $.userQuantityInLock[msg.sender] += amount;

        // Store the redemption request
        $._extRedemptionRequests[msg.sender].push(
            RedemptionRequestExt(amount, block.timestamp, duration, 0, false, false, [uint256(0), 0, 0, 0, 0])
        );

        emit RedemptionStarted(
            msg.sender,
            duration,
            block.timestamp,
            amount,
            $._extRedemptionRequests[msg.sender].length - 1
        );
    }

    /**
     * @dev Function to cancel the redemption process.
     * @param index The index of the redemption request to cancel.
     */
    function cancelRedemption(uint256 index) public whenNotPaused {
        EMDBLStorage storage $ = _getEMDBLStorage();

        RedemptionRequestExt storage request = $._extRedemptionRequests[msg.sender][index];
        if (request.completed) revert RedemptionFinish();

        // Mark the redemption request as completed
        request.completed = true;
        request.cancelled = true;
        request.endTime = block.timestamp;
        $.userQuantityInLock[msg.sender] -= request.amount;

        emit RedemptionCancelled(msg.sender, index);
    }

    /**
     * @dev Function to complete the redemption process.
     * @param index The index of the redemption request to complete.
     */
    function completeRedemption(uint256 index) public whenNotPaused {
        EMDBLStorage storage $ = _getEMDBLStorage();

        RedemptionRequestExt storage request = $._extRedemptionRequests[msg.sender][index];
        if (request.completed) revert RedemptionFinish();
        if (block.timestamp < request.startTime + request.duration) revert RedemptionNotEnded();

        // Calculate the conversion ratio based on the duration
        uint256 ratio = 1 ether;
        if (request.duration == 15 days) {
            ratio = 0.25 ether;
        } else if (request.duration == 30 days) {
            ratio = 0.35 ether;
        } else if (request.duration == 90 days) {
            ratio = 0.625 ether;
        }

        uint256 MDBLAmount = _mulWad(request.amount, ratio);
        $.totalDeductedMDBL += request.amount - MDBLAmount;

        // mark the request as completed
        request.completed = true;
        request.endTime = block.timestamp;

        // Burn the eMDBL tokens
        super._update(msg.sender, address(0), request.amount);

        $.userQuantityInLock[msg.sender] -= request.amount;

        $.MDBLAddress.transfer(msg.sender, MDBLAmount);

        emit RedemptionCompleted(msg.sender, index);
    }

    /**
     * @dev Function gets the transfer whitelist address.
     * @return The transfer address array.
     */
    function getTransferWhitelist() external view returns (address[] memory) {
        EMDBLStorage storage $ = _getEMDBLStorage();

        return $.transferWhitelist;
    }

    /**
     * @dev Function to get the redemption request at a given index.
     * @param account The address to query.
     * @return The redemption request array.
     */
    function getRedemptionRequestArray(address account) public view returns (RedemptionRequestExt[] memory) {
        EMDBLStorage storage $ = _getEMDBLStorage();

        return $._extRedemptionRequests[account];
    }

    /**
     * @dev Function to get the current user's redeemable amount.
     * @param account The address to query.
     * @return Redeemable quantity.
     */
    function getUserCanRedemptionBalance(address account) public view returns (uint256) {
        EMDBLStorage storage $ = _getEMDBLStorage();

        return
            balanceOf(account) >= $.userQuantityInLock[account]
                ? balanceOf(account) - $.userQuantityInLock[account]
                : 0;
    }

    function _checkAmountMint(address account, uint256 amount) internal {
        if (account == address(0)) revert ERC20InvalidReceiver(address(0));
        if (totalSupply() + amount > MAX_MINT_AMOUNT) revert NoMintLimitAvailable();

        _approve(account, address(this), amount);

        super._update(address(0), account, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function _getEMDBLStorage() private pure returns (EMDBLStorage storage $) {
        assembly {
            $.slot := EMDBLStorageLocation
        }
    }

    function _mulWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                mstore(0x00, 0xbac65e5b) // `MulWadFailed()`.
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), WAD)
        }
    }

    // The following functions are overrides required by Solidity.

    function _grantRole(bytes32 role, address account) internal override returns (bool) {
        EMDBLStorage storage $ = _getEMDBLStorage();

        if (role == TRANSFER_ROLE) $.transferWhitelist.push(account);

        return super._grantRole(role, account);
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        EMDBLStorage storage $ = _getEMDBLStorage();

        if (!hasRole(MINTER_ROLE, msg.sender) && $.transferWhitelist.length > 0) _checkRole(TRANSFER_ROLE);

        super._update(from, to, value);
    }
}
