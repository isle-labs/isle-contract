// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

/// @title IGovernable
/// @notice Contract module that provides a basic access control mechanism, with a governor that can be
/// granted exclusive access to specific functions. The inheriting contract must set the initial governor
/// in the constructor.
interface IGovernable {
    /*//////////////////////////////////////////////////////////////////////////
                                    EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the governor is transferred.
    /// @param oldGovernor The address of the old governor.
    /// @param newGovernor The address of the new governor.
    event TransferGovernor(address indexed oldGovernor, address indexed newGovernor);

    /*//////////////////////////////////////////////////////////////////////////
                                CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The address of the governor account or contract.
    function governor() external view returns (address governor_);

    /*//////////////////////////////////////////////////////////////////////////
                                NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Transfers the contract governor to a new address.
    ///
    /// @dev Notes:
    /// - Does not revert if the governor is the same.
    /// - This function can potentially leave the contract without an governor, thereby removing any
    /// functionality that is only available to the governor.
    ///
    /// Requirements:
    /// - `msg.sender` must be the contract governor.
    ///
    /// @param newGovernor The address of the new governor.
    function transferGovernor(address newGovernor) external;
}
