// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

/// @notice Namespace for the structs used in {PoolConfigurator}
library PoolConfigurator {
    struct Config {
        // Config that is managed by the pool admin
        bool openToPublic; // Slot 1: bool - 1 byte
        uint24 adminFee; // uint24 - 3 byte: max = 1.6e7 (1600%) / precision: 10e6 / 1e6 = 1 = 100%
        // Config that is managed by the governor
        uint24 maxCoverLiquidation;
        uint104 minCover;
        uint104 poolLimit;
    }
}

/// @notice Namespace for the structs used in {WithdrawalManager}
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

/// @notice Namespace for the structs used in {LoanManager}
library Loan {
    struct Info {
        address buyer;
        address seller;
        address receivableAsset;
        uint256 receivableTokenId;
        uint256 principal;
        uint256 drawableFunds;
        uint256 interestRate;
        uint256 lateInterestPremiumRate;
        uint256 startDate;
        uint256 dueDate;
        uint256 originalDueDate;
        uint256 gracePeriod;
        bool isImpaired;
    }

    struct LiquidationInfo {
        bool triggeredByGovernor;
        uint128 principal;
        uint120 interest;
        uint256 lateInterest;
        uint96 protocolFees;
    }

    struct PaymentInfo {
        uint24 protocolFee;
        uint24 adminFee;
        uint48 startDate;
        uint48 dueDate;
        uint128 incomingNetInterest;
        uint256 issuanceRate;
    }

    struct SortedPayment {
        uint24 previous;
        uint24 next;
        uint48 paymentDueDate;
    }

    struct Impairment {
        uint40 impairedDate; // Slot1: uint40 - Until year 36,812
        bool impariedByGovernor;
    }
}
