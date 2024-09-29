// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/// @title IGovernable
/// @notice Contract module that provides a basic access control mechanism, with a governor that can be
/// granted exclusive access to specific functions. The inheriting contract must set the initial governor
/// in the constructor.
interface IGovernable {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the pendingGovernor is accepted.
    /// @param oldGovernor The address of the old governor.
    /// @param newGovernor The address of the new governor.
    event AcceptGovernor(address indexed oldGovernor, address indexed newGovernor);

    /// @notice Emitted when the pendingGovernor is nominated.
    /// @dev Configure the pending governor value, not revert if the pending governor is not zero address
    /// @param governor The address of original governor
    /// @param pendingGovernor The address of the new pendingGovernor
    event NominateGovernor(address indexed governor, address indexed pendingGovernor);

    /// @notice Emitted when the pendingGovernor is reset to zero address
    /// @dev Reset the pending governor to zero address
    /// @param oldPendingGovernor The original configured pending governor
    event CancelPendingGovernor(address indexed oldPendingGovernor);

    /*//////////////////////////////////////////////////////////////
                           CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the governor account or contract.
    function governor() external view returns (address governor_);

    /// @notice The address of the pending governor account or contract.
    function pendingGovernor() external view returns (address pendingGovernor_);

    /*//////////////////////////////////////////////////////////////
                         NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Configure the pendingGovernor to newGovnernor parameter.
    /// @dev Does not revert if the pendingGovernor is the same, or there is already a pendingGovernor address.
    /// @param newGovernor The nominated governor, it will become the pendingGovernor.
    function nominateGovernor(address newGovernor) external;

    /// @notice The pending governor should accept and become the governor.
    /// @dev Only the pendingGovernor can trigger this function.
    function acceptGovernor() external;

    /// @notice Cancel the nominated pending governor.
    /// @dev Only the governor can trigger this function
    function cancelPendingGovenor() external;
}
