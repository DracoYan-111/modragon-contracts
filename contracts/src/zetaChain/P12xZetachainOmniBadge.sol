// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import {ECDSA} from "@openzeppelin/contracts-4.9.5/utils/cryptography/ECDSA.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable-4.8.0/proxy/utils/UUPSUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable-4.8.0/access/Ownable2StepUpgradeable.sol";
import {EIP712Upgradeable, Initializable} from "@openzeppelin/contracts-upgradeable-4.8.0/utils/cryptography/EIP712Upgradeable.sol";
import {ERC721Upgradeable, ERC721PausableUpgradeable} from "@openzeppelin/contracts-upgradeable-4.8.0/token/ERC721/extensions/ERC721PausableUpgradeable.sol";

import {SystemContract,zContract,zContext} from "@zetachain/protocol-contracts/contracts/zevm/SystemContract.sol";

import {IP12xZetachainOmniBadge} from "./interfaces/IP12xZetachainOmniBadge.sol";

contract P12xZetachainOmniBadge is
    Initializable,
    UUPSUpgradeable,
    EIP712Upgradeable,
    ERC721Upgradeable,
    ERC721PausableUpgradeable,
    Ownable2StepUpgradeable,
    IP12xZetachainOmniBadge,
    zContract
{
    bytes32 private constant WHITELIST_MINT = keccak256("WhitelistMint(address user,uint256 deadline)");

    // keccak256(abi.encode(uint256(keccak256("P12xZetachainOmniBadgeStorage")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant P12xZetachainOmniBadgeStorageLocation =
        0x1cd131e6d0ca7e68ef19f43129322449a3aeef57e2f4bd8760e571742140ec00;

    struct P12xZetachainOmniBadgeStorage {
        address _signer;
        string _tokenURI;
        uint256 _nextTokenId;
        SystemContract systemContract;
        mapping(address => bool) userReceive;
    }

    modifier onlyCanMintOnce() {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        if ($.userReceive[msg.sender]) revert AlreadyReceived();
        _;
    }

    modifier onlySystem() {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        require(msg.sender == address($.systemContract), "Only system contract can call this function");
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _systemContractAddress,
        string memory _tokenUri,
        address _signerAddress
    ) public initializer {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        $._tokenURI = _tokenUri;
        $._signer = _signerAddress;
        $.systemContract = SystemContract(_systemContractAddress);

        __ERC721_init("P12 x Zetachain OmniBadge", "P12 x Zetachain OmniBadge");
        __ERC721Pausable_init();
        __UUPSUpgradeable_init();
        __Ownable_init();
    }

    /**
     * @dev Pause related functions(only owner)
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Turn on related functions(only owner)
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Update token uri(only owner)
     * @param newTokenUri New token uri
     */
    function updateTokenUri(string calldata newTokenUri) external onlyOwner {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        $._tokenURI = newTokenUri;
        emit SetTokenUri(newTokenUri);
    }

    /**
     * @dev Update signer(only owner)
     * @param newSigner New signer adress
     */
    function updateSigner(address newSigner) external onlyOwner {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        $._signer = newSigner;
        emit SetSigner(newSigner);
    }

    /**
     * @dev Update system contract address(only owner)
     * @param newSystemContract New signer adress
     */
    function updateSystemContract(address newSystemContract) external onlyOwner {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        $.systemContract = SystemContract(newSystemContract);
        emit SetSystemContract(newSystemContract);
    }

    /**
     * @dev Whitelist mint
     * @param deadline Transaction duration
     * @param r R short-signature fields
     * @param vs VS short-signature fields
     */
    function whitelistMint(uint256 deadline, bytes32 r, bytes32 vs) external onlyCanMintOnce whenNotPaused {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        if (deadline < block.timestamp) revert MintExpired();

        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(WHITELIST_MINT, msg.sender, deadline)));

        (address recovered, ) = ECDSA.tryRecover(digest, r, vs);
        if (recovered != $._signer) revert InvalidSignature();

        $.userReceive[msg.sender] = true;

        _mint(msg.sender);

        emit UserHasReceived($._nextTokenId, msg.sender);
    }

    // The following functions are overrides required by Solidity.

    /**
     * @dev Check token uri
     * @return token uri
     */
    function tokenURI(uint256) public view override returns (string memory) {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        return $._tokenURI;
    }

    /**
     * @dev Check whether the user has received it
     * @param userAddress Check user address
     * @return true/false
     */
    function getUserReceive(address userAddress) public view returns (bool) {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        return $.userReceive[userAddress];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // The following functions are overrides required by Solidity.

    function onCrossChainCall(
        zContext calldata context,
        address zrc20,
        uint256 amount,
        bytes calldata message
    ) external virtual override onlySystem {
        // TODO: implement the logic
    }

    /**
     * @dev Override _beforeTokenTransfer from both ERC721Upgradeable and ERC721PausableUpgradeable
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721Upgradeable, ERC721PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }

    function _getP12xZetachainOmniBadgeStorage() private pure returns (P12xZetachainOmniBadgeStorage storage $) {
        assembly {
            $.slot := P12xZetachainOmniBadgeStorageLocation
        }
    }

    function _mint(address to) private {
        P12xZetachainOmniBadgeStorage storage $ = _getP12xZetachainOmniBadgeStorage();

        _safeMint(to, ++$._nextTokenId);
    }
}
