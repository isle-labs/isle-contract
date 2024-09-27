// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { Loan } from "contracts/libraries/types/DataTypes.sol";

import { PaymentList_Unit_Shared_Test } from "../../../shared/loan-manager/payment-list.t.sol";

contract RemovePaymentFromList_LoanManager_Unit_Concrete_Test is PaymentList_Unit_Shared_Test {
    using SafeCast for uint256;

    uint24 private _paymentId1;
    uint24 private _paymentId2;
    uint24 private _paymentId3;
    uint256 private _paymentDueDateMid;
    uint256 private _paymentDueDateLast;

    function setUp() public override(PaymentList_Unit_Shared_Test) {
        PaymentList_Unit_Shared_Test.setUp();
        _createDefaultPaymentList();
    }

    function test_RemovePaymentFromList() external {
        loanManagerHarness.exposed_removePaymentFromList(_paymentId1);

        Loan.SortedPayment memory actualSortedPayment_ = loanManagerHarness.getSortedPayment(_paymentId1);
        Loan.SortedPayment memory expectedSortedPayment_ =
            Loan.SortedPayment({ previous: 0, next: 0, paymentDueDate: 0 });

        assertEq(actualSortedPayment_, expectedSortedPayment_);
    }

    function test_RemovePaymentFromList_WhenRemoveEarliestPayment() external {
        loanManagerHarness.exposed_removePaymentFromList(_paymentId1);

        Loan.SortedPayment memory actualSortedPayment_ = loanManagerHarness.getSortedPayment(_paymentId2);
        Loan.SortedPayment memory expectedSortedPayment_ = Loan.SortedPayment({
            previous: 0,
            next: _paymentId3,
            paymentDueDate: SafeCast.toUint48(_paymentDueDateMid)
        });

        assertEq(actualSortedPayment_, expectedSortedPayment_);
    }

    function test_RemovePaymentFromList_WhenRemoveMiddlePayment() external {
        loanManagerHarness.exposed_removePaymentFromList(_paymentId2);

        Loan.SortedPayment memory actualSortedPaymentEarliest_ = loanManagerHarness.getSortedPayment(_paymentId1);
        Loan.SortedPayment memory expectedSortedPaymentEarliest_ = Loan.SortedPayment({
            previous: 0,
            next: _paymentId3,
            paymentDueDate: SafeCast.toUint48(defaults.REPAYMENT_TIMESTAMP())
        });

        assertEq(actualSortedPaymentEarliest_, expectedSortedPaymentEarliest_);

        Loan.SortedPayment memory actualSortedPaymentLast_ = loanManagerHarness.getSortedPayment(_paymentId3);
        Loan.SortedPayment memory expectedSortedPaymentLast_ = Loan.SortedPayment({
            previous: _paymentId1,
            next: 0,
            paymentDueDate: SafeCast.toUint48(_paymentDueDateLast)
        });

        assertEq(actualSortedPaymentLast_, expectedSortedPaymentLast_);
    }

    function test_RemovePaymentFromList_WhenRemoveLastPayment() external {
        loanManagerHarness.exposed_removePaymentFromList(_paymentId3);

        Loan.SortedPayment memory actualSortedPayment_ = loanManagerHarness.getSortedPayment(_paymentId2);
        Loan.SortedPayment memory expectedSortedPayment_ = Loan.SortedPayment({
            previous: _paymentId1,
            next: 0,
            paymentDueDate: SafeCast.toUint48(_paymentDueDateMid)
        });

        assertEq(actualSortedPayment_, expectedSortedPayment_);
    }

    function _createDefaultPaymentList() private {
        _paymentDueDateMid = defaults.REPAYMENT_TIMESTAMP() + 5 days;
        _paymentDueDateLast = defaults.REPAYMENT_TIMESTAMP() + 10 days;
        _paymentId1 = addDefaultPayment(defaults.REPAYMENT_TIMESTAMP());
        _paymentId2 = addDefaultPayment(_paymentDueDateMid);
        _paymentId3 = addDefaultPayment(_paymentDueDateLast);
    }
}
