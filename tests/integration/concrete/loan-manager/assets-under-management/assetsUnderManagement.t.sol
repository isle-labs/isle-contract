// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { LoanManager_Integration_Concrete_Test } from "../LoanManager.t.sol";
import { LoanManager_Integration_Shared_Test } from "../../../shared/loan-manager/LoanManager.t.sol";

contract AssetsUnderManagement_LoanManager_Integration_Concrete_Test is
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

    function test_AssetsUnderManagement_NoLoan() external {
        assertEq(loanManager.assetsUnderManagement(), 0);
    }

    function test_AssetsUnderManagement_OneLoan_AtStartTime() external whenLoanFunded {
        assertEq(loanManager.assetsUnderManagement(), defaults.PRINCIPAL_REQUESTED());
    }

    function test_AssetsUnderManagement_OneLoan_InMiddle_NotUpdated() external whenLoanFunded {
        vm.warp(MAY_1_2023 + 10 days);
        uint256 accruedInterestEach = defaults.NEW_RATE_ZERO_FEE_RATE() * 10 days / 1e27;
        assertEq(loanManager.assetsUnderManagement(), defaults.PRINCIPAL_REQUESTED() + accruedInterestEach);
    }

    function test_AssetsUnderManagement_OneLoan_InMiddle_Updated() external whenLoanFunded {
        vm.warp(MAY_1_2023 + 10 days);
        uint256 accruedInterestEach = defaults.NEW_RATE_ZERO_FEE_RATE() * 10 days / 1e27;

        changePrank(users.poolAdmin);
        loanManager.updateAccounting();

        uint256 accountedInterest = accruedInterestEach;
        assertEq(loanManager.assetsUnderManagement(), defaults.PRINCIPAL_REQUESTED() + accountedInterest);

        vm.warp(MAY_1_2023 + 30 days);
        accruedInterestEach = defaults.NEW_RATE_ZERO_FEE_RATE() * 20 days / 1e27;

        assertEq(
            loanManager.assetsUnderManagement(),
            defaults.PRINCIPAL_REQUESTED() + accountedInterest + accruedInterestEach
        );

        loanManager.updateAccounting();
        accountedInterest += accruedInterestEach;
        assertEq(loanManager.assetsUnderManagement(), defaults.PRINCIPAL_REQUESTED() + accountedInterest);
    }

    function test_AssetsUnderManagement_OneLoan_Defaulted_NotUpdate() external whenLoanFunded {
        vm.warp(MAY_1_2023 + 100 days);
        uint256 accruedInterestEach = defaults.NEW_RATE_ZERO_FEE_RATE() * 100 days / 1e27;
        assertEq(loanManager.assetsUnderManagement(), defaults.PRINCIPAL_REQUESTED() + accruedInterestEach);
    }

    function test_AssetsUnderManagement_OneLoan_Defaulted_Update() external whenLoanFunded {
        vm.warp(MAY_1_2023 + 100 days);

        changePrank(users.poolAdmin);
        loanManager.updateAccounting();
        uint256 accountedInterest = defaults.NEW_RATE_ZERO_FEE_RATE() * 30 days / 1e27;
        assertEq(loanManager.assetsUnderManagement(), defaults.PRINCIPAL_REQUESTED() + accountedInterest);
    }

    function test_AssetsUnderManagement_MultipleLoans_AtStartTime() external whenTwoLoansFunded {
        assertEq(loanManager.assetsUnderManagement(), defaults.PRINCIPAL_REQUESTED() * 2);
    }

    function test_AssetsUnderManagement_MultipleLoans_InMiddle_NotUpdate() external whenTwoLoansFunded {
        vm.warp(MAY_1_2023 + 10 days);
        uint256 accruedInterest = (defaults.NEW_RATE_ZERO_FEE_RATE() * 10 days) * 2 / 1e27;
        assertEq(loanManager.assetsUnderManagement(), defaults.PRINCIPAL_REQUESTED() * 2 + accruedInterest);
    }

    function test_AssetsUnderManagement_MultipleLoans_InMiddle_Update() external whenTwoLoansFunded {
        vm.warp(MAY_1_2023 + 10 days);
        uint256 accruedInterest = (defaults.NEW_RATE_ZERO_FEE_RATE() * 10 days) * 2 / 1e27;
        assertEq(loanManager.assetsUnderManagement(), defaults.PRINCIPAL_REQUESTED() * 2 + accruedInterest);

        fundDefaultLoan();
        vm.warp(MAY_1_2023 + 15 days);
        accruedInterest = (defaults.NEW_RATE_ZERO_FEE_RATE() * 10 days) * 2 / 1e27;
        // since fund another loan will trigger _advanceGlobalPaymentAccounting()
        // account interest for previous loans
        uint256 accountedInterest = accruedInterest;
        // accrue interest for the new loan
        accruedInterest = (defaults.NEW_RATE_ZERO_FEE_RATE() * 5 days) * 3 / 1e27;
        assertEq(
            loanManager.assetsUnderManagement(),
            defaults.PRINCIPAL_REQUESTED() * 3 + accountedInterest + accruedInterest
        );
    }

    function test_AssetsUnderManagement_MultipleLoans_Defaulted_NotUpdate() external whenTwoLoansFunded {
        vm.warp(MAY_1_2023 + 100 days);
        uint256 accruedInterest = (defaults.NEW_RATE_ZERO_FEE_RATE() * 100 days) * 2 / 1e27;
        assertEq(loanManager.assetsUnderManagement(), defaults.PRINCIPAL_REQUESTED() * 2 + accruedInterest);
    }

    function test_AssetsUnderManagement_MultipleLoans_Defaulted_Update() external whenTwoLoansFunded {
        vm.warp(MAY_1_2023 + 100 days);

        changePrank(users.poolAdmin);
        loanManager.updateAccounting();
        uint256 accountedInterest = (defaults.NEW_RATE_ZERO_FEE_RATE() * 30 days) * 2 / 1e27;
        assertEq(loanManager.assetsUnderManagement(), defaults.PRINCIPAL_REQUESTED() * 2 + accountedInterest);
    }
}
