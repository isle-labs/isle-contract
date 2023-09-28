// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { LoanManager_Integration_Concrete_Test } from "../LoanManager.t.sol";
import { Callable_Integration_Shared_Test } from "../../../shared/loan-manager/callable.t.sol";

contract UpdateAccounting_Integration_Concrete_Test is
    LoanManager_Integration_Concrete_Test,
    Callable_Integration_Shared_Test
{
    function setUp() public virtual override(LoanManager_Integration_Concrete_Test, Callable_Integration_Shared_Test) {
        LoanManager_Integration_Concrete_Test.setUp();
        Callable_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_FunctionPaused() external {
        changePrank(users.governor);
        lopoGlobals.setContractPause(address(loanManager), true);
        vm.expectRevert(abi.encodeWithSelector(Errors.FunctionPaused.selector, bytes4(keccak256("updateAccounting()"))));
        loanManager.updateAccounting();
    }

    function test_RevertWhen_CallerNotPoolAdminOrGovernor() external WhenNotPaused {
        changePrank(users.caller);
        vm.expectRevert(abi.encodeWithSelector(Errors.NotPoolAdminOrGovernor.selector, users.caller));
        loanManager.updateAccounting();
    }

    function test_UpdateAccounting() external WhenNotPaused WhenCallerPoolAdminOrGovernor {
        assertEq(loanManager.accruedInterest(), 0);

        createDefaultLoan();
        vm.warp(defaults.MAY_31_2023() + 70 days);

        assertEq(loanManager.accruedInterest(), defaults.NEW_RATE_ZERO_FEE_RATE() * 100 days / 1e27);
        loanManager.updateAccounting();

        assertEq(loanManager.accruedInterest(), 0);
        assertEq(loanManager.accountedInterest(), defaults.NEW_RATE_ZERO_FEE_RATE() * 30 days / 1e27);
    }
}
