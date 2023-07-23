// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ReceivableStorage } from "./ReceivableStorage.sol";
import { ILopoGlobalsLike } from "./interfaces/Interfaces.sol";

contract Receivable is
    ReceivableStorage,
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable
{
    /**
     * Storage **
     */
    address public lopoGlobals;
    ILopoGlobalsLike globals_;

    /**
     * Modifier **
     */
    modifier onlyBuyer() {
        require(globals_.isBuyer(msg.sender), "RECV:CALLER_NOT_BUYER");
        _;
    }

    modifier onlyGovernor() {
        // msg.sender == ILopoGlobalsLike(lopoGlobals).governor()
        require(msg.sender == globals_.governor(), "RECV:NOT_GOVERNOR");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _lopoGlobals) {
        _disableInitializers();
        // lopoGlobals need to be deployed first
        require(ILopoGlobalsLike(lopoGlobals = _lopoGlobals).governor() != address(0), "RECV:C:INVALID_GLOBALS");
        globals_ = ILopoGlobalsLike(lopoGlobals);
    }

    /**
     * @dev Emitted when a new receivable is created.
     */
    event AssetCreated(
        address indexed buyer,
        address indexed seller,
        uint256 indexed tokenId,
        uint256 faceAmount,
        uint256 repaymentTimestamp
    );

    // event AssetRepaid(address indexed buyer, address indexed seller, uint256 tokenId, uint256 repaidAmount);

    // event AssetDefaulted(address indexed buyer, address indexed seller, uint256 tokenId, uint256 defaultAmount);

    /**
     * @dev Initializer that sets the default admin and buyer roles
     */
    function initialize() public initializer {
        __ERC721_init("Receivable", "RECV");
        __ERC721Enumerable_init();
        __ERC721Burnable_init();
    }

    /**
     * @dev Buyer creates a new receivable
     * @param _seller The address of the seller that's expected to receive payment for this receivable
     * @param _faceAmount The amount of the receivable
     * @param _repaymentTimestamp The timestamp when the receivable is expected to be repaid
     * @param _currencyCode The currency code specified by ISO 4217 in which the receivable is expressed, e.g. 840 for
     * USD
     * @return _tokenId The id of the newly created receivable
     * @notice Only the buyer can call this function
     * @notice The input type of _faceAmount is UD60x18, which is a fixed-point number with 18 decimals
     * @notice The event faceAmount is converted to decimal with 6 decimals
     */
    function createReceivable(
        address _seller,
        UD60x18 _faceAmount,
        uint256 _repaymentTimestamp,
        uint16 _currencyCode
    )
        external
        onlyBuyer
        returns (uint256 _tokenId)
    {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter += 1;

        idToReceivableInfo[tokenId] = ReceivableInfo({
            buyer: msg.sender,
            seller: _seller,
            faceAmount: _faceAmount,
            repaymentTimestamp: _repaymentTimestamp,
            isValid: true,
            currencyCode: _currencyCode
        });

        _safeMint(_seller, tokenId);
        uint256 faceAmountToUint256 = _faceAmount.intoUint256();
        emit AssetCreated(msg.sender, _seller, tokenId, faceAmountToUint256, _repaymentTimestamp);

        return tokenId;
    }

    function getReceivableInfoById(uint256 tokenId) external view returns (ReceivableInfo memory) {
        return idToReceivableInfo[tokenId];
    }

    // The following functions are overrides required by Solidity.

    /**
     * @dev Hook that is called before any token transfer.
     * @notice not support batch transfer
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    )
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * Globals Setters **
     */

    function setLopoGlobals(address _lopoGlobals) external onlyGovernor {
        require(ILopoGlobalsLike(_lopoGlobals).governor() != address(0), "RECV:SG:INVALID_GLOBALS");
        lopoGlobals = _lopoGlobals;
    }

    /**
     * View Function **
     */

    /**
     * Helper Function **
     */
}
