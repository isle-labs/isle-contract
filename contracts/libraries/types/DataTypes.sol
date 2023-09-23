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

/// @notice Namespace for the structs used in {Receivable}
library Receivable {
    /// @param buyer The address of the buyer that's expected to pay for this receivable
    /// @param seller The address of the seller that's expected to receive payment for this receivable
    /// @param faceAmount The amount of the receivable
    /// @param repaymentTimestamp The timestamp when the receivable is expected to be repaid
    /// @param currencyCode The currency code specified by ISO 4217 in which the receivable is expressed, e.g. 840 for
    /// USD
    struct Create {
        address buyer;
        address seller;
        uint256 faceAmount;
        uint256 repaymentTimestamp;
        uint16 currencyCode;
    }

    struct Info {
        // The address of the buyer that's expected to pay for this receivable
        address buyer;
        // The address of the seller that's expected to receive payment for this receivable
        address seller;
        // The amount of the receivable
        uint256 faceAmount;
        // The timestamp when the receivable is expected to be repaid
        uint256 repaymentTimestamp;
        // The receivable is created or not
        bool isValid;
        // The currency code specified by ISO 4217 in which the receivable is expressed, e.g. 840 for USD
        uint16 currencyCode;
    }
}
