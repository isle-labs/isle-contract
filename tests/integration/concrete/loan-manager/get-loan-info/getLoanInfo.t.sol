// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { Loan } from "contracts/libraries/types/DataTypes.sol";

import { LoanManager_Integration_Concrete_Test } from "../LoanManager.t.sol";
import { LoanManager_Integration_Shared_Test } from "../../../shared/loan-manager/LoanManager.t.sol";

contract GetLoanInfo_LoanManager_Integration_Concrete_Test is
    LoanManager_Integration_Concrete_Test,
    LoanManager_Integration_Shared_Test
{
    Loan.Info LOAN_INFO;
    Loan.Info EMPTY_LOAN_INFO;

    function setUp()
        public
        virtual
        override(LoanManager_Integration_Concrete_Test, LoanManager_Integration_Shared_Test)
    {
        LoanManager_Integration_Concrete_Test.setUp();

        fundDefaultLoan();

        LOAN_INFO = Loan.Info({
            buyer: users.buyer,
            seller: users.seller,
            receivableAsset: address(receivable),
            receivableTokenId: defaults.RECEIVABLE_TOKEN_ID(),
            principal: defaults.PRINCIPAL_REQUESTED(),
            drawableFunds: defaults.PRINCIPAL_REQUESTED(),
            interestRate: defaults.INTEREST_RATE(),
            lateInterestPremiumRate: defaults.LATE_INTEREST_PREMIUM_RATE(),
            startDate: defaults.START_DATE(),
            dueDate: defaults.REPAYMENT_TIMESTAMP(),
            originalDueDate: 0,
            gracePeriod: defaults.GRACE_PERIOD(),
            isImpaired: false
        });

        EMPTY_LOAN_INFO = Loan.Info({
            buyer: address(0), // replace with actual address
            seller: address(0), // replace with actual address
            receivableAsset: address(0), // replace with actual address
            receivableTokenId: 0, // replace with actual token ID
            principal: 0, // replace with actual principal
            drawableFunds: 0, // replace with actual drawable funds
            interestRate: 0, // replace with actual interest rate
            lateInterestPremiumRate: 0, // replace with actual late interest premium rate
            startDate: 0, // replace with actual start date
            dueDate: 0, // replace with actual due date
            originalDueDate: 0, // replace with actual original due date
            gracePeriod: 0, // replace with actual grace period
            isImpaired: false // replace with actual isImpaired value
         });
    }

    function test_GetLoanInfo_InvalidLoanId() external {
        Loan.Info memory loanInfo_ = loanManager.getLoanInfo(0);
        assertEq(loanInfo_, EMPTY_LOAN_INFO);
    }

    function test_GetLoanInfo() external {
        Loan.Info memory loanInfo_ = loanManager.getLoanInfo(1);
        assertEq(loanInfo_, LOAN_INFO);
    }
}
