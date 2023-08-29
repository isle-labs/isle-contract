// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { console } from "@forge-std/console.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { Errors } from "../../contracts/libraries/Errors.sol";

import { IPoolAddressesProvider } from "../../contracts/interfaces/IPoolAddressesProvider.sol";
import { ILoanManagerEvents } from "../../contracts/interfaces/ILoanManagerEvents.sol";
import { IPool } from "../../contracts/interfaces/IPool.sol";

import { PoolConfigurator } from "../../contracts/PoolConfigurator.sol";
import { IntegrationTest } from "./Integration.t.sol";

contract LoanManagerTest is IntegrationTest, ILoanManagerEvents {
    uint256 internal _delta_ = 1e6;

    /*//////////////////////////////////////////////////////////////////////////
                                SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public override {
        super.setUp();
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function test_accruedInterest() public {
        uint256 accruedInterest_ = wrappedLoanManagerProxy.accruedInterest();
        assertEq(accruedInterest_, 0);

        _callerDepositToReceiver(users.caller, users.receiver, 1_000_000e6);
        (uint256 newRate,) = _createLoan(100_000e6);

        vm.warp(block.timestamp + 100 days);
        // even though the loan is matured, the accrued interest is still counted since nobody trigger
        // _advanceGlobalPaymentAccounting()
        accruedInterest_ = wrappedLoanManagerProxy.accruedInterest();

        assertEq(accruedInterest_, newRate * 100 days / 1e27);
    }

    function test_assetsUnderManagement() public {
        uint256 assetsUnderManagement_ = wrappedLoanManagerProxy.assetsUnderManagement();
        assertEq(assetsUnderManagement_, 0);

        _callerDepositToReceiver(users.caller, users.receiver, 1_000_000e6);
        (uint256 newRateFirst,) = _createLoan(100_000e6);

        // AUM = principalOut + accountedInterest + accruedInterest
        assetsUnderManagement_ = wrappedLoanManagerProxy.assetsUnderManagement();
        assertEq(assetsUnderManagement_, 100_000e6 + 0e6 + 0e6);

        vm.warp(block.timestamp + 100 days);

        assetsUnderManagement_ = wrappedLoanManagerProxy.assetsUnderManagement();
        assertEq(assetsUnderManagement_, 100_000e6 + 0e6 + newRateFirst * 100 days / 1e27);

        // fund another loan, and this will trigger _advanceGlobalPaymentAccounting()
        (uint256 newRateSecond,) = _createLoan(100_000e6);
        assetsUnderManagement_ = wrappedLoanManagerProxy.assetsUnderManagement();
        assertEq(assetsUnderManagement_, 200_000e6 + newRateFirst * 30 days / 1e27 + 0e6);

        vm.warp(block.timestamp + 100 days);
        assetsUnderManagement_ = wrappedLoanManagerProxy.assetsUnderManagement();
        assertEq(assetsUnderManagement_, 200_000e6 + newRateFirst * 30 days / 1e27 + newRateSecond * 100 days / 1e27);
    }

    function test_getLoanPaymentDetailedBreakdown() public {
        (uint256 principal_, uint256[2] memory interest_) = wrappedLoanManagerProxy.getLoanPaymentDetailedBreakdown(0);
        assertEq(principal_, 0);
        assertEq(interest_[0], 0);
        assertEq(interest_[1], 0);

        _callerDepositToReceiver(users.caller, users.receiver, 1_000_000e6);
        (, uint256 periodicInterestRate) = _createLoan(100_000e6);
        uint256 dueDate = block.timestamp + 30 days;

        // loanId and paymentId are start from 1
        (principal_, interest_) = wrappedLoanManagerProxy.getLoanPaymentDetailedBreakdown(1);

        assertEq(principal_, 100_000e6);
        assertEq(interest_[0], 100_000e6 * periodicInterestRate / 1e18);
        assertEq(interest_[1], 0);

        vm.warp(block.timestamp + 35 days + 1); // 5 days + 1 second after due date
        (principal_, interest_) = wrappedLoanManagerProxy.getLoanPaymentDetailedBreakdown(1);

        // 5 days late
        uint256 fullDaysLate_ = ((block.timestamp - dueDate + (1 days - 1)) / 1 days) * 1 days;

        assertEq(principal_, 100_000e6);
        assertEq(interest_[0], 100_000e6 * periodicInterestRate / 1e18);
        // interest rate become 12% + 20% after 30 days
        uint256 latePeriodicInterestRate = uint256(0.32e6) * (1e18 / 1e6) * fullDaysLate_ / 365 days; // e6 * e18 / e6 =
            // e18
        assertEq(interest_[1], 100_000e6 * latePeriodicInterestRate / 1e18);
    }

    function test_getLoanPaymentBreakdown() public {
        (uint256 principal_, uint256 interest_) = wrappedLoanManagerProxy.getLoanPaymentBreakdown(0);
        assertEq(principal_, 0);
        assertEq(interest_, 0);

        _callerDepositToReceiver(users.caller, users.receiver, 1_000_000e6);
        (, uint256 periodicInterestRate) = _createLoan(100_000e6);
        uint256 dueDate = block.timestamp + 30 days;

        (principal_, interest_) = wrappedLoanManagerProxy.getLoanPaymentBreakdown(1);
        uint256 interest = 100_000e6 * periodicInterestRate / 1e18;
        uint256 lateInterest = 0e6;
        assertEq(principal_, 100_000e6);
        assertEq(interest_, interest + lateInterest);

        vm.warp(block.timestamp + 35 days + 1);
        (principal_, interest_) = wrappedLoanManagerProxy.getLoanPaymentBreakdown(1);
        assertEq(principal_, 100_000e6);
        uint256 fullDaysLate_ = ((block.timestamp - dueDate + (1 days - 1)) / 1 days) * 1 days;
        uint256 latePeriodicInterestRate = uint256(0.32e6) * (1e18 / 1e6) * fullDaysLate_ / 365 days;
        lateInterest = 100_000e6 * latePeriodicInterestRate / 1e18;
        assertEq(interest_, interest + lateInterest);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                EXTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function test_updateAccounting() public {
        _callerDepositToReceiver(users.caller, users.receiver, 1_000_000e6);
        (uint256 newRateFirst,) = _createLoan(100_000e6);

        // AUM = principalOut + accountedInterest + accruedInterest
        uint256 assetsUnderManagement_ = wrappedLoanManagerProxy.assetsUnderManagement();
        assertEq(assetsUnderManagement_, 100_000e6 + 0e6 + 0e6);

        vm.warp(block.timestamp + 100 days);

        // case1: nobody trigger _advanceGlobalPaymentAccounting()
        assetsUnderManagement_ = wrappedLoanManagerProxy.assetsUnderManagement();
        assertEq(assetsUnderManagement_, 100_000e6 + 0e6 + newRateFirst * 100 days / 1e27);

        // case2: pool admin manually trigger _advanceGlobalPaymentAccounting()
        vm.prank(users.pool_admin);
        wrappedLoanManagerProxy.updateAccounting();
        assetsUnderManagement_ = wrappedLoanManagerProxy.assetsUnderManagement();
        assertEq(assetsUnderManagement_, 100_000e6 + newRateFirst * 30 days / 1e27 + 0e6);
    }

    function test_approveLoan() public {
        uint256 receivablesTokenId_ = _createReceivable(1_000_000e6);

        address collateralAsset_ = address(wrappedReceivableProxy);
        uint256 gracePeriod_ = 7;
        uint256 principalRequested_ = 1_000_000e6;
        uint256[2] memory rates_ = [uint256(0.12e6), uint256(0.2e6)];
        uint256 fee_ = 0;

        vm.expectEmit(true, true, true, true);
        emit LoanApproved(1);

        vm.prank(users.pool_admin);
        uint16 loanId_ = wrappedLoanManagerProxy.approveLoan(
            collateralAsset_, receivablesTokenId_, gracePeriod_, principalRequested_, rates_, fee_
        );
        assertEq(loanId_, 1);
    }

    function test_fundLoan() public {
        // create receivable collateral
        uint256 receivablesTokenId_ = _createReceivable(100_000e6);

        // caller deposits some funds into the pool
        _callerDepositToReceiver(users.caller, users.receiver, 1_000_000e6);
        uint256 poolBalanceBefore = IERC20(address(usdc)).balanceOf(address(pool));

        uint16 loanId_ = _approveLoan(receivablesTokenId_, 100_000e6);

        // emit by fundLoan()
        vm.expectEmit(true, true, true, true);
        emit PrincipalOutUpdated(100_000e6);

        // emit by _queuePayment()
        vm.expectEmit(true, true, true, true);
        uint256 periodicInterestRate = uint256(0.12e6) * (1e18 / 1e6) * 30 days / 365 days; // e6 * e18 / e6 = e18
        uint256 interest = 100_000e6 * periodicInterestRate / 1e18; // e6 * e18 / e18 = e6
        uint256 netInterest = interest * (1e6 - 0e6) / 1e6; // e6 * e6 / e6 = e6
        uint256 newRate = netInterest * 1e27 / 30 days; // e6 * e27 / seconds = e33 / seconds
        emit PaymentAdded(1, 1, 0, 0, block.timestamp, block.timestamp + 30 days, newRate);

        // emit by _updateIssuanceParams()
        vm.expectEmit(true, true, true, true);
        // domainEnd = uint48(block.timestamp + 30 days)
        // issuanceRate = newRate;
        // accountedInterest = 0e6;
        emit IssuanceParamsUpdated(uint48(block.timestamp + 30 days), newRate, 0e6);

        // assume that the poolCover is higher than minCoverAmount
        // and the liquidity of the pool after funding is higher than lockedLiquidity for withdrawing
        _fundLoan(loanId_);

        uint256 poolBalanceAfter = IERC20(address(usdc)).balanceOf(address(pool));

        assertEq(poolBalanceAfter, poolBalanceBefore - 100_000e6);

        // second loan with same params
        vm.warp(block.timestamp + 15 days);
        receivablesTokenId_ = _createReceivable(100_000e6);

        // _callerDepositToReceiver() already reached the liquidity cap
        poolBalanceBefore = IERC20(address(usdc)).balanceOf(address(pool));

        loanId_ = _approveLoan(receivablesTokenId_, 100_000e6);

        // emit by fundLoan()
        vm.expectEmit(true, true, true, true);
        emit PrincipalOutUpdated(200_000e6);

        // emit by _queuePayment()
        vm.expectEmit(true, true, true, true);
        emit PaymentAdded(2, 2, 0, 0, block.timestamp, block.timestamp + 30 days, newRate);

        // emit by _updateIssuanceParams()
        vm.expectEmit(true, true, true, true);
        uint112 accruedInterest = uint112(newRate * 15 days / 1e27);
        uint112 accountedInterest = 0 + uint112(accruedInterest); // earliest payment not in the past
        uint256 issuanceRate = newRate * 2;
        emit IssuanceParamsUpdated(uint48(block.timestamp + 15 days), issuanceRate, accountedInterest);

        _fundLoan(loanId_);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice the interest rate and duration is pre-defined to be 12% APR and 30 days
    function _createLoan(uint256 principalRequested_)
        internal
        returns (uint256 newRate_, uint256 periodicInterestRate_)
    {
        uint256 receivablesTokenId = _createReceivable(principalRequested_);
        uint16 loanId = _approveLoan(receivablesTokenId, principalRequested_);
        _fundLoan(loanId);

        periodicInterestRate_ = uint256(0.12e6) * (1e18 / 1e6) * 30 days / 365 days; // e6 * e18 / e6 = e18
        uint256 interest = principalRequested_ * periodicInterestRate_ / 1e18; // e6 * e18 / e18 = e6
        uint256 netInterest = interest * (1e6 - 0e6) / 1e6; // e6 * e6 / e6 = e6
        newRate_ = netInterest * 1e27 / 30 days; // e6 * e27 / seconds = e33 / seconds
    }
}
