// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { Loan } from "contracts/libraries/types/DataTypes.sol";

import { PaymentList_Unit_Shared_Test } from "../../../shared/loan-manager/payment-list.t.sol";

contract AddPaymentToList_LoanManager_Unit_Concrete_Test is PaymentList_Unit_Shared_Test {
    using SafeCast for uint256;

    function test_AddPaymentToList() external {
        uint24 paymentId_ = addDefaultPayment(defaults.REPAYMENT_TIMESTAMP());

        Loan.SortedPayment memory actualSortedPayment_ = loanManagerHarness.getSortedPayment(paymentId_);
        Loan.SortedPayment memory expectedSortedPayment_ = Loan.SortedPayment({
            previous: 0,
            next: 0,
            paymentDueDate: SafeCast.toUint48(defaults.REPAYMENT_TIMESTAMP())
        });

        assertEq(actualSortedPayment_, expectedSortedPayment_);
    }

    function test_AddPaymentToList_WhenAddEarliestPayment() external {
        uint24 paymentId1_ = addDefaultPayment(defaults.REPAYMENT_TIMESTAMP());

        uint256 paymentDueDateEarliest_ = defaults.REPAYMENT_TIMESTAMP() - 1 days;
        uint24 paymentId2_ = loanManagerHarness.exposed_addPaymentToList(SafeCast.toUint48(paymentDueDateEarliest_));

        Loan.SortedPayment memory actualSortedPaymentEarliest_ = loanManagerHarness.getSortedPayment(paymentId2_);
        Loan.SortedPayment memory expectedSortedPaymentEarliest_ = Loan.SortedPayment({
            previous: 0,
            next: paymentId1_,
            paymentDueDate: SafeCast.toUint48(paymentDueDateEarliest_)
        });

        assertEq(actualSortedPaymentEarliest_, expectedSortedPaymentEarliest_);
    }

    function test_AddPaymentToList_WhenAddLatestPayment() external {
        uint24 paymentId1_ = addDefaultPayment(defaults.REPAYMENT_TIMESTAMP());

        uint256 paymentDueDateLatest_ = defaults.REPAYMENT_TIMESTAMP() + 10 days;
        uint24 paymentId2_ = loanManagerHarness.exposed_addPaymentToList(SafeCast.toUint48(paymentDueDateLatest_));

        Loan.SortedPayment memory actualSortedPaymentLatest_ = loanManagerHarness.getSortedPayment(paymentId2_);
        Loan.SortedPayment memory expectedSortedPaymentLatest_ = Loan.SortedPayment({
            previous: paymentId1_,
            next: 0,
            paymentDueDate: SafeCast.toUint48(paymentDueDateLatest_)
        });

        assertEq(actualSortedPaymentLatest_, expectedSortedPaymentLatest_);
    }

    function test_AddPaymentToList_WhenAddMidPayment() external {
        uint24 paymentId1_ = addDefaultPayment(defaults.REPAYMENT_TIMESTAMP());

        uint256 paymentDueDateLatest_ = defaults.REPAYMENT_TIMESTAMP() + 10 days;
        uint24 paymentId2_ = loanManagerHarness.exposed_addPaymentToList(SafeCast.toUint48(paymentDueDateLatest_));

        // To test add payment in the middle of the list
        uint256 paymentDueDateMid_ = defaults.REPAYMENT_TIMESTAMP() + 5 days;
        uint24 paymentId3_ = loanManagerHarness.exposed_addPaymentToList(SafeCast.toUint48(paymentDueDateMid_));

        Loan.SortedPayment memory actualSortedPaymentMid_ = loanManagerHarness.getSortedPayment(paymentId3_);
        Loan.SortedPayment memory expectedSortedPaymentMid_ = Loan.SortedPayment({
            previous: paymentId1_,
            next: paymentId2_,
            paymentDueDate: SafeCast.toUint48(paymentDueDateMid_)
        });

        assertEq(actualSortedPaymentMid_, expectedSortedPaymentMid_);
    }
}
