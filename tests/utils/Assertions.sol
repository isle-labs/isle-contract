// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { PRBMathAssertions } from "@prb/math/test/Assertions.sol";
import { PRBTest } from "@prb/test/PRBTest.sol";

import { WithdrawalManager, Receivable, Loan } from "contracts/libraries/types/DataTypes.sol";

abstract contract Assertions is PRBTest, PRBMathAssertions {
    /// @dev Compares two {WithdrawalManager.CycleConfig} struct entities.
    function assertEq(WithdrawalManager.CycleConfig memory a, WithdrawalManager.CycleConfig memory b) internal {
        assertEq(a.initialCycleId, b.initialCycleId, "config.initialCycleId");
        assertEq(a.initialCycleTime, b.initialCycleTime, "config.initialCycleTime");
        assertEq(a.cycleDuration, b.cycleDuration, "config.cycleDuration");
        assertEq(a.windowDuration, b.windowDuration, "config.windowDuration");
    }

    /// @dev Compares two {Receivable.Info} struct entities.
    function assertEq(Receivable.Info memory a, Receivable.Info memory b) internal {
        assertEq(a.buyer, b.buyer, "info.buyer");
        assertEq(a.seller, b.seller, "info.seller");
        assertEq(a.faceAmount, b.faceAmount, "info.faceAmount");
        assertEq(a.repaymentTimestamp, b.repaymentTimestamp, "info.repaymentTimestamp");
        assertEq(a.currencyCode, b.currencyCode, "info.currencyCode");
        assertEq(a.isValid, b.isValid, "info.isValid");
    }

    /// @dev Compares two {Loan.Info} struct entities.
    function assertEq(Loan.Info memory a, Loan.Info memory b) internal {
        assertEq(a.buyer, b.buyer, "info.buyer");
        assertEq(a.seller, b.seller, "info.seller");
        assertEq(a.receivableAsset, b.receivableAsset, "info.receivableAsset");
        assertEq(a.receivableTokenId, b.receivableTokenId, "info.receivableTokenId");
        assertEq(a.principal, b.principal, "info.principal");
        assertEq(a.drawableFunds, b.drawableFunds, "info.drawableFunds");
        assertEq(a.interestRate, b.interestRate, "info.interestRate");
        assertEq(a.lateInterestPremiumRate, b.lateInterestPremiumRate, "info.lateInterestPremiumRate");
        assertEq(a.startDate, b.startDate, "info.startDate");
        assertEq(a.dueDate, b.dueDate, "info.dueDate");
        assertEq(a.originalDueDate, b.originalDueDate, "info.originalDueDate");
        assertEq(a.gracePeriod, b.gracePeriod, "info.gracePeriod");
        assertEq(a.isImpaired, b.isImpaired, "info.isImpaired");
    }

    /// @dev Compares two {Loan.SortedPayment} struct entities.
    function assertEq(Loan.SortedPayment memory a, Loan.SortedPayment memory b) internal {
        assertEq(a.previous, b.previous, "sortedPayment.previous");
        assertEq(a.next, b.next, "sortedPayment.next");
        assertEq(a.paymentDueDate, b.paymentDueDate, "sortedPayment.paymentDueDate");
    }
}
