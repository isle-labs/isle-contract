// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { ILoanManagerStorage } from "./interfaces/ILoanManagerStorage.sol";

abstract contract LoanManagerStorage is ILoanManagerStorage {
    struct LoanInfo {
        address buyer;
        address seller;
        address collateralAsset;
        uint256 collateralTokenId;
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

    uint16 public override loanCounter;
    uint24 public override paymentCounter;
    uint24 public override paymentWithEarliestDueDate;
    uint48 public override domainStart;
    uint48 public override domainEnd;
    uint112 public override accountedInterest;
    uint128 public override principalOut;
    uint128 public override unrealizedLosses;
    uint256 public override issuanceRate;

    address public override fundsAsset;
    address public override collateralAsset;

    mapping(uint16 => uint24) public override paymentIdOf;
    mapping(uint16 => Impairment) public impairmentFor;
    mapping(uint256 => PaymentInfo) public payments;
    mapping(uint256 => SortedPayment) public sortedPayments;
    mapping(uint16 => LiquidationInfo) public liquidationInfoFor;

    mapping(uint16 => LoanInfo) internal _loans;
}
