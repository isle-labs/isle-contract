// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { LoanManager_Integration_Concrete_Test } from "../loanManager.t.sol";
import { Callable_Integration_Shared_Test } from "../../../shared/loan-manager/Callable.t.sol";

contract RepayLoan_Integration_Concrete_Test is
    LoanManager_Integration_Concrete_Test,
    Callable_Integration_Shared_Test
{
    function setUp() public virtual override(LoanManager_Integration_Concrete_Test, Callable_Integration_Shared_Test) {
        LoanManager_Integration_Concrete_Test.setUp();
        Callable_Integration_Shared_Test.setUp();
    }

    modifier WhenSellerWithdrawFunds() {
        _;
    }

    function test_RevertWhen_FunctionPaused() external {
        changePrank(users.governor);
        lopoGlobals.setContractPause(address(loanManager), true);

        changePrank(users.poolAdmin);
        vm.expectRevert(abi.encodeWithSelector(Errors.FunctionPaused.selector, bytes4(keccak256("repayLoan(uint16)"))));
        loanManager.repayLoan(1);
    }

    function test_RepayLoan_WhenSellerNotWithdrawFunds() external WhenNotPaused {
        // set the admin and protocol fee rate to 10% and 0.5% respectively
        _setAdminAndProtocolFeeRate();

        uint256 poolBalanceBefore = usdc.balanceOf(address(pool));

        createLoan();

        vm.warp(defaults.MAY_31_2023());

        vm.expectEmit(true, true, true, true);
        emit LoanRepaid(1, defaults.PRINCIPAL_REQUESTED(), defaults.INTEREST());

        vm.expectEmit(true, true, true, true);
        emit FeesPaid(1, defaults.ADMIN_FEE(), defaults.PROTOCOL_FEE());

        vm.expectEmit(true, true, true, true);
        emit FundsDistributed(1, defaults.PRINCIPAL_REQUESTED(), defaults.NET_INTEREST());

        vm.expectEmit(true, true, true, true);
        emit PrincipalOutUpdated(0);

        vm.expectEmit(true, true, true, true);
        emit PaymentRemoved(1, 1);

        vm.expectEmit(true, true, true, true);
        emit IssuanceParamsUpdated(uint48(defaults.MAY_31_2023()), 0, 0);

        changePrank(users.buyer);
        loanManager.repayLoan(1);

        uint256 poolBalanceAfter = usdc.balanceOf(address(pool));

        // check seller still owns the receivable
        assertEq(receivable.balanceOf(address(loanManager)), 0);
        assertEq(receivable.balanceOf(address(users.seller)), 1);

        // check the usdc balance of the pool increased by the interest less the admin and protocol fees
        assertEq(poolBalanceAfter - poolBalanceBefore, defaults.NET_INTEREST());
    }

    function test_RepayLoan() external WhenNotPaused WhenSellerWithdrawFunds {
        // set the admin and protocol fee rate to 10% and 0.5% respectively
        _setAdminAndProtocolFeeRate();

        uint256 poolBalanceBefore = usdc.balanceOf(address(pool));

        createLoan();

        changePrank(users.seller);
        receivable.approve(address(loanManager), defaults.RECEIVABLE_TOKEN_ID());
        loanManager.withdrawFunds(1, address(users.seller), defaults.PRINCIPAL_REQUESTED());

        vm.warp(defaults.MAY_31_2023());

        vm.expectEmit(true, true, true, true);
        emit LoanRepaid(1, defaults.PRINCIPAL_REQUESTED(), defaults.INTEREST());

        vm.expectEmit(true, true, true, true);
        emit FeesPaid(1, defaults.ADMIN_FEE(), defaults.PROTOCOL_FEE());

        vm.expectEmit(true, true, true, true);
        emit FundsDistributed(1, defaults.PRINCIPAL_REQUESTED(), defaults.NET_INTEREST());

        vm.expectEmit(true, true, true, true);
        emit PrincipalOutUpdated(0);

        vm.expectEmit(true, true, true, true);
        emit PaymentRemoved(1, 1);

        vm.expectEmit(true, true, true, true);
        emit AssetBurned(defaults.RECEIVABLE_TOKEN_ID());

        vm.expectEmit(true, true, true, true);
        emit IssuanceParamsUpdated(uint48(defaults.MAY_31_2023()), 0, 0);

        changePrank(users.buyer);
        loanManager.repayLoan(1);

        uint256 poolBalanceAfter = usdc.balanceOf(address(pool));

        // check no one owns the receivable
        assertEq(receivable.balanceOf(address(loanManager)), 0);
        assertEq(receivable.balanceOf(address(users.seller)), 0);

        // check the usdc balance of the pool increased by the interest less the admin and protocol fees
        assertEq(poolBalanceAfter - poolBalanceBefore, defaults.NET_INTEREST());
    }

    function _setAdminAndProtocolFeeRate() internal {
        changePrank(users.governor);
        lopoGlobals.setProtocolFeeRate(address(poolConfigurator), defaults.PROTOCOL_FEE_RATE());
        changePrank(users.poolAdmin);
        poolConfigurator.setAdminFeeRate(defaults.ADMIN_FEE_RATE());
    }
}
