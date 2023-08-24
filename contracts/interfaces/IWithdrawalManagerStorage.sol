// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/*//////////////////////////////////////////////////////////////////////////
                            STORAGE
//////////////////////////////////////////////////////////////////////////*/

interface IWithdrawalManagerStorage {
    struct CycleConfig {
        uint64 initialCycleId; // Identifier of the first withdrawal cycle using this config
        uint64 initialCycleTime; // Starting timestamp of the first withdrawal cycle using this config
        uint64 cycleDuration; // Cycle duration of this config
        uint64 windowDuration; // Window duration of this config
    }

    /// @notice Gets the id of the latest config
    function latestConfigId() external view returns (uint256 configId_);

    /// @notice Gets the configuration of a config id
    /// @param configId_ The id of the config
    /// @return initialCycleId_ The id of the initial cycle
    /// @return initialCycleTime_ The starting timestamp of the initial cycle
    /// @return cycleDuration_ The duration of the cycle
    /// @return windowDuration_ The duration of the window
    function cycleConfigs(uint256 configId_)
        external
        returns (uint64 initialCycleId_, uint64 initialCycleTime_, uint64 cycleDuration_, uint64 windowDuration_);

    /// @notice Gets the exit cycle id of an account
    /// @param account_ The address of the account
    /// @return cycleId_ The id of the exit cycle
    function exitCycleId(address account_) external view returns (uint256 cycleId_);

    /// @notice Gets the locked shares of an account
    /// @param account_ The address of the account
    /// @return lockedShares_ The amount of locked shares under the account
    function lockedShares(address account_) external view returns (uint256 lockedShares_);

    /// @notice Gets the total locked shares of a cycle
    /// @param cycleId_ The id of the cycle
    /// @return totalCycleShares_ The total amount of locked shares under the cycle
    function totalCycleShares(uint256 cycleId_) external view returns (uint256 totalCycleShares_);
}
