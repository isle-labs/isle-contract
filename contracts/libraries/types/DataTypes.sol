// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

library WithdrawalManager {
    struct CycleConfig {
        uint64 initialCycleId; // Identifier of the first withdrawal cycle using this config
        uint64 initialCycleTime; // Starting timestamp of the first withdrawal cycle using this config
        uint64 cycleDuration; // Cycle duration of this config
        uint64 windowDuration; // Window duration of this config
    }
}
