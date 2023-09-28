// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { LoanManager_Integration_Concrete_Test } from "../LoanManager.t.sol";
import { Callable_Integration_Shared_Test } from "../../../shared/loan-manager/callable.t.sol";

contract RemoveLoanImpairment_Integration_Concrete_Test is
    LoanManager_Integration_Concrete_Test,
    Callable_Integration_Shared_Test
{
    function setUp() public virtual override(LoanManager_Integration_Concrete_Test, Callable_Integration_Shared_Test) {
        LoanManager_Integration_Concrete_Test.setUp();
        Callable_Integration_Shared_Test.setUp();

        createDefaultLoan();
    }

    modifier WhenPaymentIdIsNotZero() {
        _;
    }

    modifier WhenLoanIsImpaired() {
        _;
    }

    modifier WhenBlockTimestampIsLessThanOrEqualToOriginalDueDate() {
        _;
    }

    function test_RevertWhen_FunctionPaused() external {
        changePrank(users.governor);
        lopoGlobals.setContractPause(address(loanManager), true);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.FunctionPaused.selector, bytes4(keccak256("removeLoanImpairment(uint16)")))
        );

        loanManager.removeLoanImpairment(1);
    }

    function test_RevertWhen_CallerNotPoolAdminOrGovernor() external WhenNotPaused {
        changePrank(users.caller);
        vm.expectRevert(abi.encodeWithSelector(Errors.NotPoolAdminOrGovernor.selector, address(users.caller)));
        loanManager.removeLoanImpairment(1);
    }

    function test_RevertWhen_PaymentIdIsZero() external WhenNotPaused WhenCallerPoolAdminOrGovernor {
        changePrank(users.poolAdmin);
        vm.expectRevert(abi.encodeWithSelector(Errors.LoanManager_NotLoan.selector, 0));
        loanManager.removeLoanImpairment(0);
    }

    function test_RevertWhen_LoanIsNotImpaired()
        external
        WhenNotPaused
        WhenCallerPoolAdminOrGovernor
        WhenPaymentIdIsNotZero
    {
        changePrank(users.poolAdmin);
        vm.expectRevert(abi.encodeWithSelector(Errors.LoanManager_LoanNotImpaired.selector, 1));
        loanManager.removeLoanImpairment(1);
    }

    function test_RevertWhen_BlockTimestampIsGreaterThanOriginalDueDate()
        external
        WhenNotPaused
        WhenCallerPoolAdminOrGovernor
        WhenPaymentIdIsNotZero
        WhenLoanIsImpaired
    {
        changePrank(users.poolAdmin);
        loanManager.impairLoan(1);

        vm.warp(defaults.MAY_31_2023() + 1);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LoanManager_PastDueDate.selector, 1, defaults.MAY_31_2023(), defaults.MAY_31_2023() + 1
            )
        );
        loanManager.removeLoanImpairment(1);
    }

    function test_RemoveLoanImpairment()
        external
        WhenNotPaused
        WhenCallerPoolAdminOrGovernor
        WhenPaymentIdIsNotZero
        WhenLoanIsImpaired
        WhenBlockTimestampIsLessThanOrEqualToOriginalDueDate
    {
        vm.warp(MAY_1_2023 + 10 days);

        changePrank(users.poolAdmin);
        loanManager.impairLoan(1);

        vm.warp(MAY_1_2023 + 15 days);

        vm.expectEmit(true, true, true, true);
        emit UnrealizedLossesUpdated(uint128(0));

        vm.expectEmit(true, true, true, true);
        // also add the accrued interest in the 5 days of impairment
        // notice that the interestRate in the impaired period is the same as normal period
        uint112 accountedInterest = uint112(defaults.NEW_RATE_ZERO_FEE_RATE() * 15 days / 1e27);
        emit IssuanceParamsUpdated(uint48(defaults.MAY_31_2023()), defaults.NEW_RATE_ZERO_FEE_RATE(), accountedInterest);

        vm.expectEmit(true, true, true, true);
        emit ImpairmentRemoved(1, defaults.MAY_31_2023());

        loanManager.removeLoanImpairment(1);

        // check the unrealized losses
        assertEq(loanManager.unrealizedLosses(), 0);
    }
}
