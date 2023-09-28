// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { LoanManager_Integration_Concrete_Test } from "../LoanManager.t.sol";
import { Callable_Integration_Shared_Test } from "../../../shared/loan-manager/callable.t.sol";

contract ImpairLoan_Integration_Concrete_Test is
    LoanManager_Integration_Concrete_Test,
    Callable_Integration_Shared_Test
{
    function setUp() public virtual override(LoanManager_Integration_Concrete_Test, Callable_Integration_Shared_Test) {
        LoanManager_Integration_Concrete_Test.setUp();
        Callable_Integration_Shared_Test.setUp();

        createLoan();
    }

    modifier WhenLoanIsNotImpaired() {
        _;
    }

    modifier WhenPaymentIdIsNotZero() {
        _;
    }

    function test_RevertWhen_FunctionPaused() external {
        changePrank(users.governor);
        lopoGlobals.setContractPause(address(loanManager), true);

        vm.expectRevert(abi.encodeWithSelector(Errors.FunctionPaused.selector, bytes4(keccak256("impairLoan(uint16)"))));

        loanManager.impairLoan(1);
    }

    function test_RevertWhen_CallerNotPoolAdminOrGovernor() external WhenNotPaused {
        changePrank(users.caller);
        vm.expectRevert(abi.encodeWithSelector(Errors.NotPoolAdminOrGovernor.selector, address(users.caller)));
        loanManager.impairLoan(1);
    }

    function test_RevertWhen_LoanIsImpaired() external WhenNotPaused WhenCallerPoolAdminOrGovernor {
        changePrank(users.poolAdmin);
        loanManager.impairLoan(1);

        vm.expectRevert(abi.encodeWithSelector(Errors.LoanManager_LoanImpaired.selector, 1));
        loanManager.impairLoan(1);
    }

    function test_RevertWhen_PaymentIdIsZero()
        external
        WhenNotPaused
        WhenCallerPoolAdminOrGovernor
        WhenLoanIsNotImpaired
    {
        changePrank(users.poolAdmin);
        vm.expectRevert(abi.encodeWithSelector(Errors.LoanManager_NotLoan.selector, 0));
        loanManager.impairLoan(0);
    }

    function test_impairLoan()
        external
        WhenNotPaused
        WhenCallerPoolAdminOrGovernor
        WhenLoanIsNotImpaired
        WhenPaymentIdIsNotZero
    {
        vm.warp(MAY_1_2023 + 10 days);
        changePrank(users.poolAdmin);

        uint112 accountedInterest = uint112(defaults.NEW_RATE_ZERO_FEE_RATE() * 10 days / 1e27);

        vm.expectEmit(true, true, true, true);
        emit IssuanceParamsUpdated(uint48(block.timestamp), 0, accountedInterest);

        vm.expectEmit(true, true, true, true);
        emit UnrealizedLossesUpdated(uint128(defaults.PRINCIPAL_REQUESTED() + accountedInterest));

        vm.expectEmit(true, true, true, true);
        emit LoanImpaired(1, block.timestamp);

        loanManager.impairLoan(1);

        //check the unrealized losses
        assertEq(loanManager.unrealizedLosses(), defaults.PRINCIPAL_REQUESTED() + accountedInterest);
    }
}
