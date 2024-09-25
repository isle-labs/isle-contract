// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { LoanManager_Integration_Concrete_Test } from "../LoanManager.t.sol";
import { LoanManager_Integration_Shared_Test } from "../../../shared/loan-manager/LoanManager.t.sol";

contract GetLoanPaymentDetailedBreakdown_LoanManager_Integration_Concrete_Test is
    LoanManager_Integration_Concrete_Test,
    LoanManager_Integration_Shared_Test
{
    function setUp()
        public
        virtual
        override(LoanManager_Integration_Concrete_Test, LoanManager_Integration_Shared_Test)
    {
        LoanManager_Integration_Concrete_Test.setUp();
    }

    function test_GetLoanPaymentDetailedBreakdown_NonExistLoanId() external {
        (uint256 principal_, uint256[2] memory interest_) = loanManager.getLoanPaymentDetailedBreakdown(0);
        assertEq(principal_, 0);
        assertEq(interest_[0], 0);
        assertEq(interest_[1], 0);
    }

    function test_GetLoanPaymentDetailedBreakdown_ExistLoanId_NotDefaulted() external {
        createDefaultLoan();
        vm.warp(MAY_1_2023 + 10 days);
        (uint256 principal_, uint256[2] memory interest_) = loanManager.getLoanPaymentDetailedBreakdown(1);
        assertEq(principal_, defaults.PRINCIPAL_REQUESTED());
        assertEq(interest_[0], defaults.INTEREST());
        assertEq(interest_[1], 0);
    }

    function test_GetLoanPaymentDetailedBreakdown_ExistLoanId_Defaulted() external {
        createDefaultLoan();
        // 9 days + 1s -> 10 full days late
        vm.warp(defaults.MAY_31_2023() + 9 days + 1);

        (uint256 principal_, uint256[2] memory interest_) = loanManager.getLoanPaymentDetailedBreakdown(1);
        assertEq(principal_, defaults.PRINCIPAL_REQUESTED());
        assertEq(interest_[0], defaults.INTEREST());
        assertEq(interest_[1], defaults.LATE_INTEREST());
    }
}
