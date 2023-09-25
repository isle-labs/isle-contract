// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { LoanManager_Integration_Concrete_Test } from "../loanManager.t.sol";
import { Callable_Integration_Shared_Test } from "../../../shared/loan-manager/Callable.t.sol";

contract WithdrawFunds_Integration_Concrete_Test is
    LoanManager_Integration_Concrete_Test,
    Callable_Integration_Shared_Test
{
    function setUp() public virtual override(LoanManager_Integration_Concrete_Test, Callable_Integration_Shared_Test) {
        LoanManager_Integration_Concrete_Test.setUp();
        Callable_Integration_Shared_Test.setUp();

        createLoan();
    }

    modifier WhenCallerLoanSeller() {
        _;
    }

    modifier WhenWithdrawAmountLessThanOrEqualToDrawableAmount() {
        _;
    }

    function test_RevertWhen_FunctionPaused() external {
        changePrank(users.governor);
        lopoGlobals.setContractPause(address(loanManager), true);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.FunctionPaused.selector, bytes4(keccak256("withdrawFunds(uint16,address,uint256)"))
            )
        );
        loanManager.withdrawFunds(1, address(0), 0);
    }

    function test_RevertWhen_CallerNotLoanSeller() external WhenNotPaused {
        changePrank(users.caller);
        vm.expectRevert(abi.encodeWithSelector(Errors.LoanManager_CallerNotSeller.selector, users.seller));
        loanManager.withdrawFunds(1, address(0), 0);
    }

    function test_RevertWhen_WithdrawAmountGreaterThanDrawableAmount() external WhenNotPaused WhenCallerLoanSeller {
        changePrank(users.seller);
        uint256 principalRequested = defaults.PRINCIPAL_REQUESTED();
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LoanManager_Overdraw.selector, 1, principalRequested + 1, principalRequested)
        );
        loanManager.withdrawFunds(1, address(users.seller), principalRequested + 1);
    }

    function test_withdrawFunds()
        external
        WhenNotPaused
        WhenCallerLoanSeller
        WhenWithdrawAmountLessThanOrEqualToDrawableAmount
    {
        changePrank(users.seller);
        uint256 principalRequested = defaults.PRINCIPAL_REQUESTED();
        uint256 loanManagerBalanceBefore = usdc.balanceOf(address(loanManager));

        receivable.approve(address(loanManager), defaults.RECEIVABLE_TOKEN_ID());

        vm.expectEmit(true, true, true, true);
        emit FundsWithdrawn(1, principalRequested);

        loanManager.withdrawFunds(1, address(users.seller), principalRequested);

        uint256 loanManagerBalanceAfter = usdc.balanceOf(address(loanManager));

        assertEq(receivable.balanceOf(address(users.seller)), 0);
        assertEq(receivable.balanceOf(address(loanManager)), 1);
        assertEq(loanManagerBalanceAfter, loanManagerBalanceBefore - principalRequested);
    }
}
