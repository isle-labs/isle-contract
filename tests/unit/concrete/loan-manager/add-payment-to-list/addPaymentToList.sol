// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { Loan } from "contracts/libraries/types/DataTypes.sol";

import { Base_Test } from "../../../../Base.t.sol";
import { LoanManager_Unit_Shared_Test } from "../../../shared/loan-manager/LoanManager.t.sol";

import { LoanManagerHarness } from "tests/mocks/LoanManagerHarness.sol";

contract AddPaymentToList_LoanManager_Unit_Concrete_Test is LoanManager_Unit_Shared_Test {
    using SafeCast for uint256;

    LoanManagerHarness private loanManagerHarness;
    uint256 private _paymentDueDateDefault;

    function setUp() public virtual override {
        Base_Test.setUp();

        // Setup pool addresses provider
        changePrank(users.governor);
        isleGlobals = deployGlobals();
        poolAddressesProvider = deployPoolAddressesProvider(isleGlobals);
        setDefaultGlobals(poolAddressesProvider);

        loanManagerHarness = new LoanManagerHarness(poolAddressesProvider);
        _paymentDueDateDefault = defaults.REPAYMENT_TIMESTAMP();
    }

    function test_AddPaymentToList() external {
        uint24 paymentId_ = _addDefaultPayment(_paymentDueDateDefault);

        Loan.SortedPayment memory actualSortedPayment_ = loanManagerHarness.getSortedPayment(paymentId_);
        Loan.SortedPayment memory expectedSortedPayment_ =
            Loan.SortedPayment({ previous: 0, next: 0, paymentDueDate: SafeCast.toUint48(_paymentDueDateDefault) });

        assertEq(actualSortedPayment_, expectedSortedPayment_);
    }

    function test_AddPaymentToList_WhenAddPaymentAtHead() external {
        uint24 paymentId1_ = _addDefaultPayment(_paymentDueDateDefault);

        uint256 paymentDueDateHead_ = defaults.REPAYMENT_TIMESTAMP() - 1 days;
        uint24 paymentId2_ = loanManagerHarness.exposed_addPaymentToList(SafeCast.toUint48(paymentDueDateHead_));

        Loan.SortedPayment memory actualSortedPaymentHead_ = loanManagerHarness.getSortedPayment(paymentId2_);
        Loan.SortedPayment memory expectedSortedPaymentHead_ = Loan.SortedPayment({
            previous: 0,
            next: paymentId1_,
            paymentDueDate: SafeCast.toUint48(paymentDueDateHead_)
        });

        assertEq(actualSortedPaymentHead_, expectedSortedPaymentHead_);
    }

    function test_AddPaymentToList_WhenAddPaymentAtTail() external {
        uint24 paymentId1_ = _addDefaultPayment(_paymentDueDateDefault);

        uint256 paymentDueDateTail_ = defaults.REPAYMENT_TIMESTAMP() + 10 days;
        uint24 paymentId2_ = loanManagerHarness.exposed_addPaymentToList(SafeCast.toUint48(paymentDueDateTail_));

        Loan.SortedPayment memory actualSortedPaymentTail_ = loanManagerHarness.getSortedPayment(paymentId2_);
        Loan.SortedPayment memory expectedSortedPaymentTail_ = Loan.SortedPayment({
            previous: paymentId1_,
            next: 0,
            paymentDueDate: SafeCast.toUint48(paymentDueDateTail_)
        });

        assertEq(actualSortedPaymentTail_, expectedSortedPaymentTail_);
    }

    function test_AddPaymentToList_WhenAddPaymentAtMiddle() external {
        uint24 paymentId1_ = _addDefaultPayment(_paymentDueDateDefault);

        uint256 paymentDueDateTail_ = defaults.REPAYMENT_TIMESTAMP() + 10 days;
        uint24 paymentId2_ = loanManagerHarness.exposed_addPaymentToList(SafeCast.toUint48(paymentDueDateTail_));

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

    function _addDefaultPayment(uint256 paymentDueDate_) private returns (uint24 paymentId_) {
        paymentId_ = loanManagerHarness.exposed_addPaymentToList(SafeCast.toUint48(paymentDueDate_));
    }
}
