// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Receivable } from "../libraries/types/DataTypes.sol";

import { IReceivableEvent } from "../interfaces/IReceivableEvent.sol";
import { IGovernable } from "./IGovernable.sol";

import { ReceivableStorage } from "../ReceivableStorage.sol";

interface IReceivable is IGovernable, IReceivableEvent {
    /*//////////////////////////////////////////////////////////////////////////
                            UUPS FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialAdmin_ The address of the admin
    function initialize(address initialAdmin_) external;

    /// @dev Mint a new receivable
    /// @notice Only the buyer can call this function
    /// @notice The event faceAmount is converted to decimal with 6 decimals
    /// @param create_ The struct containing the information of the receivable to be created
    /// @return tokenId_ The id of the newly created receivable
    function createReceivable(Receivable.Create memory create_) external returns (uint256 tokenId_);

    /// @dev Get the information of a receivable
    /// @param tokenId_ The id of the receivable
    /// @return info_ The struct containing the information of the receivable
    function getReceivableInfoById(uint256 tokenId_) external view returns (Receivable.Info memory info_);

    function burnReceivable(uint256 tokenId_) external;
}
