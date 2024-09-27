// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Receivable } from "../libraries/types/DataTypes.sol";

import { IReceivableEvent } from "../interfaces/IReceivableEvent.sol";

import { ReceivableStorage } from "../ReceivableStorage.sol";

interface IReceivable is IReceivableEvent {
    /// @notice The address of the governor account or contract.
    function governor() external view returns (address governor_);

    /*//////////////////////////////////////////////////////////////
                             UUPS FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Initializes the Receivable.
    /// @param initialGovernor_ The address of the governor.
    function initialize(address initialGovernor_) external;

    /// @notice Mint a new receivable.
    /// @dev The event faceAmount is converted to decimal with 6 decimals.
    /// @param create_ The struct containing the information of the receivable to be created.
    /// @return tokenId_ The id of the newly created receivable.
    function createReceivable(Receivable.Create memory create_) external returns (uint256 tokenId_);

    /// @dev Get the information of a receivable.
    /// @param tokenId_ The id of the receivable.
    /// @return info_ The struct containing the information of the receivable.
    function getReceivableInfoById(uint256 tokenId_) external view returns (Receivable.Info memory info_);

    /// @dev Burn a receivable.
    /// @param tokenId_ The id of the receivable.
    function burnReceivable(uint256 tokenId_) external;
}
