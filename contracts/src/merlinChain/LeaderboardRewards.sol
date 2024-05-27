// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {NoncesUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/NoncesUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {UUPSUpgradeable, Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {IeMDBL, ILeaderboardRewards} from "./interfaces/ILeaderboardRewards.sol";

contract LeaderboardRewards is
    Initializable,
    PausableUpgradeable,
    Ownable2StepUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    EIP712Upgradeable,
    NoncesUpgradeable,
    ILeaderboardRewards
{
    using SafeERC20 for IERC20;

    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("PermitClaim(address tokenAddress,address to,uint256 amount,uint256 nonce,uint256 deadline)");

    // keccak256(abi.encode(uint256(keccak256("LeaderboardRewardsStorage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant LeaderboardRewardsStorageLocation =
        0x12eccda39a912e3db87acc3ba69815bb09f308eb3f31f6e92e1723d50cf67800;

    struct LeaderboardRewardsStorage {
        address signer;
        address MDBLToken;
        address eMDBLToken;
        mapping(address => bool) blackList;
        mapping(address => uint256) userHasUsedMDBL;
        mapping(address => uint256) userHasUsedeMDBL;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialOwner,
        address _signer,
        address _MDBLToken,
        address _eMDBLToken
    ) public initializer {
        LeaderboardRewardsStorage storage $ = _getLeaderboardRewardsStorage();

        $.signer = _signer;
        $.MDBLToken = _MDBLToken;
        $.eMDBLToken = _eMDBLToken;

        __Pausable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __Ownable_init(initialOwner);
        __EIP712_init_unchained("LeaderboardRewards", "1");
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * Set new singer
     * @param newSinger New singer address
     */
    function setSinger(address newSinger) external onlyOwner {
        LeaderboardRewardsStorage storage $ = _getLeaderboardRewardsStorage();

        $.signer = newSinger;

        emit UpdateSinger(newSinger);
    }

    /**
     * Set new token address
     * @param tokenAddress New token address
     * @param opt Token index
     */
    function setTokenAddress(address tokenAddress, uint8 opt) external onlyOwner {
        LeaderboardRewardsStorage storage $ = _getLeaderboardRewardsStorage();

        opt == 0 ? $.MDBLToken = tokenAddress : $.eMDBLToken = tokenAddress;

        emit UpdateTokenAddress(tokenAddress, opt);
    }

    /**
     * Set black list
     * @param userAddress User address list
     */
    function setBlackList(address[] calldata userAddress) external onlyOwner {
        LeaderboardRewardsStorage storage $ = _getLeaderboardRewardsStorage();

        for (uint256 i; i < userAddress.length; ) {
            $.blackList[userAddress[i]] = true;

            unchecked {
                ++i;
            }
        }

        emit UpdateBlackList(userAddress);
    }

    /**
     * Get rewards by signing
     * @param tokenAddress Received token address
     * @param to Receiver address
     * @param amount Receiver amount
     * @param deadline Effective time
     */
    function permitClaim(
        address tokenAddress,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public nonReentrant whenNotPaused {
        LeaderboardRewardsStorage storage $ = _getLeaderboardRewardsStorage();

        if ($.blackList[to]) revert UserInBlackList();

        if (block.timestamp > deadline) revert ERC2612ExpiredSignature(deadline);

        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, tokenAddress, to, amount, _useNonce(to), deadline));

        address recoverSigner = ECDSA.recover(_hashTypedDataV4(structHash), v, r, s);
        if ($.signer != recoverSigner) revert ERC2612InvalidSigner($.signer, recoverSigner);

        uint256 transferAmount;
        if (tokenAddress == $.MDBLToken) {
            transferAmount = amount - $.userHasUsedMDBL[to];
            $.userHasUsedMDBL[to] += transferAmount;

            IERC20(tokenAddress).safeTransfer(to, transferAmount);
        }

        if (tokenAddress == $.eMDBLToken) {
            transferAmount = amount - $.userHasUsedeMDBL[to];
            $.userHasUsedeMDBL[to] += transferAmount;

            // Use eMDBL mint function
            IeMDBL($.eMDBLToken).mint(to, transferAmount);
        }

        emit PermitClaimToken(tokenAddress, to, transferAmount);
    }

    /**
     * Get user rewards
     * @param userAddress User address
     * @return User rewards
     */
    function getUserRewardsReceived(address userAddress) public view returns (uint256, uint256) {
        LeaderboardRewardsStorage storage $ = _getLeaderboardRewardsStorage();

        return ($.userHasUsedMDBL[userAddress], $.userHasUsedeMDBL[userAddress]);
    }

    function _getLeaderboardRewardsStorage() private pure returns (LeaderboardRewardsStorage storage $) {
        assembly {
            $.slot := LeaderboardRewardsStorageLocation
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }

    function nonces(address owner) public view virtual override returns (uint256) {
        return super.nonces(owner);
    }
}
