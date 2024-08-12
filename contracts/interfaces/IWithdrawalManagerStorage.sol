// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/*//////////////////////////////////////////////////////////////////////////
                            STORAGE
//////////////////////////////////////////////////////////////////////////*/

interface IWithdrawalManagerStorage {
    /// @notice Gets the id of the latest config.
    /// @return configId_ The id of the latest config.
    function latestConfigId() external view returns (uint256 configId_);

    /// @notice Gets the exit cycle id of an account.
    /// @param account_ The address of the account.
    /// @return cycleId_ The id of the exit cycle.
    function exitCycleId(address account_) external view returns (uint256 cycleId_);

    /// @notice Gets the locked shares of an account.
    /// @param account_ The address of the account.
    /// @return lockedShares_ The amount of locked shares under the account.
    function lockedShares(address account_) external view returns (uint256 lockedShares_);

    /// @notice Gets the total locked shares of a cycle.
    /// @param cycleId_ The id of the cycle.
    /// @return totalCycleShares_ The total amount of locked shares under the cycle.
    function totalCycleShares(uint256 cycleId_) external view returns (uint256 totalCycleShares_);
}
