// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { Errors } from "contracts/libraries/Errors.sol";

import { LoanManager_Integration_Concrete_Test } from "../LoanManager.t.sol";
import { Callable_Integration_Shared_Test } from "../../../shared/loan-manager/callable.t.sol";

contract RepayLoan_LoanManager_Integration_Concrete_Test is
    LoanManager_Integration_Concrete_Test,
    Callable_Integration_Shared_Test
{
    function setUp() public virtual override(LoanManager_Integration_Concrete_Test, Callable_Integration_Shared_Test) {
        LoanManager_Integration_Concrete_Test.setUp();
        Callable_Integration_Shared_Test.setUp();
    }

    modifier whenSellerWithdrawFunds() {
        _;
    }

    function test_RevertWhen_FunctionPaused() external {
        changePrank(users.governor);
        isleGlobals.setContractPaused(address(loanManager), true);

        changePrank(users.poolAdmin);
        vm.expectRevert(abi.encodeWithSelector(Errors.FunctionPaused.selector, bytes4(keccak256("repayLoan(uint16)"))));
        loanManager.repayLoan(1);
    }

    function test_RevertWhen_NotLoan() external whenNotPaused {
        vm.expectRevert(abi.encodeWithSelector(Errors.LoanManager_NotLoan.selector, 0));
        loanManager.repayLoan(0);
    }

    function test_RepayLoan_WhenLoanImpaired() external {
        createDefaultLoan();

        changePrank(users.poolAdmin);
        loanManager.impairLoan(1);

        vm.expectEmit(true, true, true, true);
        emit UnrealizedLossesUpdated(0);

        changePrank(users.buyer);
        loanManager.repayLoan(1);
    }

    function test_RepayLoan_WhenAfterDueDate() external {
        uint256 dueDate_ = defaults.REPAYMENT_TIMESTAMP();

        createDefaultLoan();

        vm.warp(dueDate_ + 1);

        changePrank(users.buyer);
        loanManager.repayLoan(1);

        assertEq(loanManager.accountedInterest(), 0);
    }

    function test_RepayLoan_WhenSellerNotWithdrawFunds() external whenNotPaused {
        // set the admin and protocol fee rate to 10% and 0.5% respectively
        _setAdminAndProtocolFee();

        uint256 poolBalanceBefore = usdc.balanceOf(address(pool));

        createDefaultLoan();

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

        IERC721 receivable = IERC721(address(receivable));

        // check seller still owns the receivable
        assertEq(receivable.balanceOf(address(loanManager)), 0);
        assertEq(receivable.balanceOf(address(users.seller)), 1);

        // check the usdc balance of the pool increased by the interest less the admin and protocol fees
        assertEq(poolBalanceAfter - poolBalanceBefore, defaults.NET_INTEREST());
    }

    function test_RepayLoan() external whenNotPaused whenSellerWithdrawFunds {
        // set the admin and protocol fee rate to 10% and 0.5% respectively
        _setAdminAndProtocolFee();

        uint256 poolBalanceBefore = usdc.balanceOf(address(pool));

        createDefaultLoan();
        IERC721 receivable = IERC721(address(receivable));

        changePrank(users.seller);
        receivable.approve(address(loanManager), defaults.RECEIVABLE_TOKEN_ID());
        loanManager.withdrawFunds(1, address(users.seller));

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

    function _setAdminAndProtocolFee() internal {
        changePrank(users.governor);
        isleGlobals.setProtocolFee(defaults.PROTOCOL_FEE_RATE());
        changePrank(users.poolAdmin);
        poolConfigurator.setAdminFee(defaults.ADMIN_FEE_RATE());
    }
}
