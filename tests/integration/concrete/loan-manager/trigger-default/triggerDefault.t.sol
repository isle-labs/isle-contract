// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { LoanManager_Integration_Concrete_Test } from "../LoanManager.t.sol";
import { Callable_Integration_Shared_Test } from "../../../shared/loan-manager/Callable.t.sol";

contract TriggerDefault_Integration_Concrete_Test is
    LoanManager_Integration_Concrete_Test,
    Callable_Integration_Shared_Test
{
    function setUp() public virtual override(LoanManager_Integration_Concrete_Test, Callable_Integration_Shared_Test) {
        LoanManager_Integration_Concrete_Test.setUp();
        Callable_Integration_Shared_Test.setUp();

        createLoan();
    }

    modifier WhenBlockTimestampGreaterThanDueDatePlusGracePeriod() {
        _;
    }

    modifier WhenPaymentIdIsNotZero() {
        _;
    }

    function test_RevertWhen_FunctionPaused() external {
        changePrank(users.governor);
        lopoGlobals.setContractPause(address(loanManager), true);

        changePrank(users.poolAdmin);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.FunctionPaused.selector, bytes4(keccak256("triggerDefault(uint16)")))
        );
        loanManager.triggerDefault(1);
    }

    function test_RevertWhen_CallerNotPoolAdmin() external WhenNotPaused {
        changePrank(users.governor);
        vm.expectRevert(abi.encodeWithSelector(Errors.NotPoolAdmin.selector, address(users.governor)));
        loanManager.triggerDefault(1);
    }

    function test_RevertWhen_BlockTimestampLessThanOrEqualToDueDatePlusGracePeriod()
        external
        WhenNotPaused
        WhenCallerPoolAdmin
    {
        vm.warp(defaults.MAY_31_2023() + defaults.GRACE_PERIOD());
        changePrank(users.poolAdmin);

        vm.expectRevert(abi.encodeWithSelector(Errors.LoanManager_NotPastDueDatePlusGracePeriod.selector, 1));
        loanManager.triggerDefault(1);
    }

    function test_RevertWhen_PaymentIdIsZero()
        external
        WhenNotPaused
        WhenCallerPoolAdmin
        WhenBlockTimestampGreaterThanDueDatePlusGracePeriod
    {
        changePrank(users.poolAdmin);
        vm.warp(defaults.MAY_31_2023() + defaults.GRACE_PERIOD() + 1);
        vm.expectRevert(abi.encodeWithSelector(Errors.LoanManager_NotLoan.selector, 0));
        loanManager.triggerDefault(0);
    }

    function test_TriggerDefault()
        external
        WhenNotPaused
        WhenCallerPoolAdmin
        WhenBlockTimestampGreaterThanDueDatePlusGracePeriod
        WhenPaymentIdIsNotZero
    {
        // 10 days late = 30 days + (7 days grace period + 2 days + 1s)
        vm.warp(defaults.MAY_31_2023() + defaults.GRACE_PERIOD() + 2 days + 1);

        vm.expectEmit(true, true, true, true);
        emit PrincipalOutUpdated(0);

        vm.expectEmit(true, true, true, true);
        emit IssuanceParamsUpdated(uint48(block.timestamp), 0, 0);

        (uint256 remainingLosses, uint256 protocolFees) = loanManager.triggerDefault(1);

        (uint256 principal, uint256[2] memory interests) = loanManager.getLoanPaymentDetailedBreakdown(1);

        uint256 netInterest = defaults.NEW_RATE_ZERO_FEE_RATE() * defaults.PERIOD() / 1e27;

        assertEq(principal, defaults.PRINCIPAL_REQUESTED());
        assertEq(interests[1], defaults.LATE_INTEREST());
        assertEq(remainingLosses, defaults.PRINCIPAL_REQUESTED() + netInterest + defaults.LATE_INTEREST());
        assertEq(protocolFees, 0);
    }
}
