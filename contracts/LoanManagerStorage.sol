// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { ILoanManager } from "./interfaces/ILoanManager.sol";

abstract contract LoanManagerStorage is ILoanManager {
    struct Loan {
        address borrower;
        uint256 principal;
        uint256 interestRate;
        uint256 lateInterestPremiumRate;
        uint256 issuanceRate;
        uint256 startDate;
        uint256 dueDate;
        uint256 gracePeriod;
    }

    struct Impairment {
        uint40 impairedDate; // Slot1: uint40 - Until year 36,812
        bool impariedByGovernor;
    }

    mapping(uint16 => Loan) public loans;
    mapping(uint16 => Impairment) public impairmentFor;

    uint40 public domainStart;
    uint112 public accountedInterest;
    uint128 public principalOut;
    uint128 public override unrealizedLosses;
    uint256 public issuanceRate;

    address public fundsAsset;
}
