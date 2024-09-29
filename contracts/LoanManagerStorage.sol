// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { Loan } from "./libraries/types/DataTypes.sol";
import { ILoanManagerStorage } from "./interfaces/ILoanManagerStorage.sol";

abstract contract LoanManagerStorage is ILoanManagerStorage {
    uint16 public override loanCounter;
    uint24 public override paymentCounter;
    uint24 public override paymentWithEarliestDueDate;
    uint48 public override domainStart;
    uint48 public override domainEnd;
    uint112 public override accountedInterest;
    uint128 public override principalOut;
    uint128 public override unrealizedLosses;
    uint256 public override issuanceRate;

    address public override asset;

    mapping(uint16 => uint24) public override paymentIdOf;
    mapping(uint16 => Loan.Impairment) public impairmentFor;
    mapping(uint256 => Loan.PaymentInfo) public payments;
    mapping(uint256 => Loan.SortedPayment) public sortedPayments;
    mapping(uint16 => Loan.LiquidationInfo) public liquidationInfoFor;

    mapping(uint16 => Loan.Info) internal _loans;
}
