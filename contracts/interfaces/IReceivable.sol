// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { ReceivableStorage } from "../ReceivableStorage.sol";
import { IReceivableEvent } from "../interfaces/IReceivableEvent.sol";

interface IReceivable is IReceivableEvent {
    /*//////////////////////////////////////////////////////////////////////////
                            UUPS FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function initialize(address lopoGlobals_) external;

    function getImplementation() external view returns (address);

    function createReceivable(
        address buyer_,
        address seller_,
        UD60x18 faceAmount_,
        uint256 repaymentTimestam_,
        uint16 currencyCode_
    )
        external
        returns (uint256 tokenId_);

    function getReceivableInfoById(uint256 tokenId_) external view returns (ReceivableStorage.ReceivableInfo memory);
}
