// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { ERC721EnumerableUpgradeable } from
    "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import { ERC721BurnableUpgradeable } from
    "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ReceivableStorage } from "./ReceivableStorage.sol";
import { IReceivable } from "./interfaces/IReceivable.sol";
import { ILopoGlobals } from "./interfaces/ILopoGlobals.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Adminable } from "./abstracts/Adminable.sol";
import { Errors } from "./libraries/Errors.sol";

contract Receivable is
    ReceivableStorage,
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    UUPSUpgradeable,
    Adminable,
    IReceivable
{
    /*//////////////////////////////////////////////////////////////////////////
                            UUPS FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(address newImplementation) internal override onlyGovernor { }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    /*//////////////////////////////////////////////////////////////////////////
                            Storage
    //////////////////////////////////////////////////////////////////////////*/
    address public override lopoGlobals;
    ILopoGlobals globals_;

    /*//////////////////////////////////////////////////////////////////////////
                            Modifiers
    //////////////////////////////////////////////////////////////////////////*/
    modifier onlyBuyer() {
        if (!globals_.isBuyer(msg.sender)) {
            revert Errors.Receivable_CallerNotBuyer(msg.sender);
        }
        _;
    }

    modifier onlyGovernor() {
        if (msg.sender != governor()) {
            revert Errors.Receivable_CallerNotGovernor(governor(), msg.sender);
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // _disableInitializers();
    }

    /**
     * @dev Initializer that sets the default admin and buyer roles
     */
    function initialize(address lopoGlobals_) public initializer {
        __ERC721_init("Receivable", "RECV");
        __ERC721Enumerable_init();
        __ERC721Burnable_init();
        if (ILopoGlobals(lopoGlobals = lopoGlobals_).governor() == address(0)) {
            revert Errors.Receivable_InvalidGlobals(address(lopoGlobals_));
        }
        globals_ = ILopoGlobals(lopoGlobals);
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
        override
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

    function getReceivableInfoById(uint256 tokenId) external view override returns (ReceivableInfo memory) {
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

    /*//////////////////////////////////////////////////////////////////////////
                            Global Setter
    //////////////////////////////////////////////////////////////////////////*/

    function setLopoGlobals(address lopoGlobals_) external override onlyGovernor {
        if (ILopoGlobals(lopoGlobals_).governor() == address(0)) {
            revert Errors.Receivable_InvalidGlobals(lopoGlobals_);
        }
        lopoGlobals = lopoGlobals_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////////////////*/

    function governor() public view override returns (address) {
        return globals_.governor();
    }
}
