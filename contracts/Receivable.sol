// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { ERC721EnumerableUpgradeable } from
    "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import { ERC721BurnableUpgradeable } from
    "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import { Errors } from "./libraries/Errors.sol";

import { ILopoGlobals } from "./interfaces/ILopoGlobals.sol";
import { IReceivable } from "./interfaces/IReceivable.sol";
import { IAdminable } from "./interfaces/IAdminable.sol";

import { Adminable } from "./abstracts/Adminable.sol";
import { ReceivableStorage } from "./ReceivableStorage.sol";

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

    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin { }

    function getImplementation() external view override returns (address) {
        return _getImplementation();
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // _disableInitializers();
    }

    /**
     * @dev Initializer that sets the default admin and buyer roles
     */
    function initialize(address initialAdmin_) external override initializer {
        __ERC721_init("Receivable", "RECV");
        __ERC721Enumerable_init();
        __ERC721Burnable_init();

        admin = initialAdmin_;
        emit IAdminable.TransferAdmin({ oldAdmin: address(0), newAdmin: initialAdmin_ });
    }

    /**
     * @dev Mint a new receivable
     * @param buyer_ The address of the buyer that's expected to pay for this receivable
     * @param seller_ The address of the seller that's expected to receive payment for this receivable
     * @param faceAmount_ The amount of the receivable
     * @param repaymentTimestamp_ The timestamp when the receivable is expected to be repaid
     * @param currencyCode_ The currency code specified by ISO 4217 in which the receivable is expressed, e.g. 840 for
     * USD
     * @return tokenId_ The id of the newly created receivable
     * @notice Only the buyer can call this function
     * @notice The input type of faceAmount_ is UD60x18, which is a fixed-point number with 18 decimals
     * @notice The event faceAmount is converted to decimal with 6 decimals
     */
    function createReceivable(
        address buyer_,
        address seller_,
        UD60x18 faceAmount_,
        uint256 repaymentTimestamp_,
        uint16 currencyCode_
    )
        external
        override
        returns (uint256 tokenId_)
    {
        tokenId_ = _tokenIdCounter;
        _tokenIdCounter += 1;

        idToReceivableInfo[tokenId_] = ReceivableInfo({
            buyer: buyer_,
            seller: seller_,
            faceAmount: faceAmount_,
            repaymentTimestamp: repaymentTimestamp_,
            isValid: true,
            currencyCode: currencyCode_
        });

        _safeMint(seller_, tokenId_);
        uint256 faceAmountToUint256 = faceAmount_.intoUint256();
        emit AssetCreated(buyer_, seller_, tokenId_, faceAmountToUint256, repaymentTimestamp_);

        return tokenId_;
    }

    function burnReceivable(uint256 tokenId_) external {
        ERC721BurnableUpgradeable.burn(tokenId_);
        emit AssetBurned(tokenId_);
    }

    function getReceivableInfoById(uint256 tokenId_) external view override returns (ReceivableInfo memory) {
        return idToReceivableInfo[tokenId_];
    }

    // The following functions are overrides required by Solidity.

    /**
     * @dev Hook that is called before any token transfer.
     * @notice not support batch transfer
     */
    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 tokenId_,
        uint256 batchSize_
    )
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from_, to_, tokenId_, batchSize_);
    }

    // function _burn(uint256 tokenId_) internal override(ERC721Upgradeable) {
    //     super._burn(tokenId_);
    // }

    function supportsInterface(bytes4 interfaceId_)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId_);
    }
}
