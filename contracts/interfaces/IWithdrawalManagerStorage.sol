// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/*//////////////////////////////////////////////////////////////////////////
                            STORAGE
//////////////////////////////////////////////////////////////////////////*/

interface IWithdrawalManagerStorage {
    struct CycleConfig {
        uint64 initialCycleId;
        uint64 initialCycleTime;
        uint64 cycleDuration;
        uint64 windowDuration;
    }

    function cycleConfigs(uint256 configId_)
        external
        returns (uint64 initialCycleId_, uint64 initialCycleTime_, uint64 cycleDuration_, uint64 windowDuration_);

    function exitCycleId(address account_) external view returns (uint256 cycleId_);

    function latestConfigId() external view returns (uint256 configId_);

    function lockedShares(address account_) external view returns (uint256 lockedShares_);

    function totalCycleShares(uint256 cycleId_) external view returns (uint256 totalCycleShares_);
}
