// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { LoanManager_Integration_Concrete_Test } from "../loanManager.t.sol";
import { Loan_Integration_Shared_Test } from "../../../shared/loan-manager/loan.t.sol";

contract AccruedInterest_Integration_Concrete_Test is
    LoanManager_Integration_Concrete_Test,
    Loan_Integration_Shared_Test
{
    function setUp() public virtual override(LoanManager_Integration_Concrete_Test, Loan_Integration_Shared_Test) {
        LoanManager_Integration_Concrete_Test.setUp();
    }

    function test_AccruedInterest_NoLoan() external {
        assertEq(loanManager.accruedInterest(), 0);
    }

    function test_AccruedInterest_ExistNotMaturedLoan() external {
        createLoan();
        vm.warp(MAY_1_2023 + 15 days);
        uint256 accruedInterest = defaults.NEW_RATE_ZERO_FEE_RATE() * 15 days / 1e27;

        assertEq(loanManager.accruedInterest(), accruedInterest);
    }
    function test_AccruedInterest_ExistMaturedLoan() external {
        createLoan();
        vm.warp(MAY_1_2023 + 30 days + 70 days);
        uint256 accruedInterest = defaults.NEW_RATE_ZERO_FEE_RATE() * 100 days / 1e27;

        assertEq(loanManager.accruedInterest(), accruedInterest);
    }
}
