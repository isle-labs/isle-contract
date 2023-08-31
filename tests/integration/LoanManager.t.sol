// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { console } from "@forge-std/console.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { Errors } from "../../contracts/libraries/Errors.sol";

import { IPoolAddressesProvider } from "../../contracts/interfaces/IPoolAddressesProvider.sol";
import { ILoanManagerEvents } from "../../contracts/interfaces/ILoanManagerEvents.sol";
import { IPool } from "../../contracts/interfaces/IPool.sol";
import { ILopoGlobals } from "../../contracts/interfaces/ILopoGlobals.sol";

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

    function test_repayLoan() public {
        // set the admin and protocol fee rate to 10% and 0.5%
        _setAdminAndProtocolFeeRate(0.1e6, 0.005e6);

        _callerDepositToReceiver(users.caller, users.receiver, 1_000_000e6);
        (, uint256 periodicInterestRate) = _createLoan(100_000e6);

        vm.warp(block.timestamp + 15 days);

        // before balance
        uint256 poolBalanceBefore = IERC20(address(usdc)).balanceOf(address(pool));
        uint256 poolAdminBalanceBefore = IERC20(address(usdc)).balanceOf(users.pool_admin);
        uint256 protocolVaultBalanceBefore =
            IERC20(address(usdc)).balanceOf(ILopoGlobals(wrappedLopoGlobalsProxy).lopoVault());

        // emit by repayLoan()
        vm.expectEmit(true, true, true, true);
        uint256 interest = 100_000e6 * periodicInterestRate / 1e18;
        emit LoanRepaid(1, 100_000e6, interest);

        // emit by _distributeClaimedFunds()
        vm.expectEmit(true, true, true, true);
        uint256 adminFee = interest * 0.1e6 / 1e6;
        uint256 protocolFee = interest * 0.005e6 / 1e6;
        uint256 netInterest = interest - adminFee - protocolFee;
        emit FeesPaid(1, adminFee, protocolFee);

        vm.expectEmit(true, true, true, true);
        emit FundsDistributed(1, 100_000e6, netInterest);

        // emit by repayLoan()
        vm.expectEmit(true, true, true, true);
        emit PrincipalOutUpdated(0);

        // emit by _handlePaymentAccounting()
        vm.expectEmit(true, true, true, true);
        emit PaymentRemoved(1, 1);

        // emit by _updateIssuanceParams()
        vm.expectEmit(true, true, true, true);
        // since there is no other loan, the domainEnd is set to block.timestamp
        emit IssuanceParamsUpdated(uint48(block.timestamp), 0, 0);

        vm.startPrank(users.buyer);
        // buyer already approve the allowance to the loanManager
        wrappedLoanManagerProxy.repayLoan(1);

        // after balance
        uint256 poolBalanceAfter = IERC20(address(usdc)).balanceOf(address(pool));
        uint256 poolAdminBalanceAfter = IERC20(address(usdc)).balanceOf(users.pool_admin);
        uint256 protocolVaultBalanceAfter =
            IERC20(address(usdc)).balanceOf(ILopoGlobals(wrappedLopoGlobalsProxy).lopoVault());

        assertEq(poolBalanceAfter, poolBalanceBefore + 100_000e6 + netInterest);
        assertEq(poolAdminBalanceAfter, poolAdminBalanceBefore + adminFee);
        assertEq(protocolVaultBalanceAfter, protocolVaultBalanceBefore + protocolFee);
    }

    function test_withdrawFunds() public {
        _callerDepositToReceiver(users.caller, users.receiver, 1_000_000e6);

        // before balance
        uint256 poolBalanceBefore = IERC20(address(usdc)).balanceOf(address(pool));
        uint256 sellerBalanceBefore = IERC20(address(usdc)).balanceOf(users.seller);

        // notice that once the pool admin funds loan, the pool balance will be deducted
        (, uint256 periodicInterestRate) = _createLoan(100_000e6);

        vm.expectEmit(true, true, true, true);
        emit FundsWithdrawn(1, 100_000e6);

        // seller withdraws the funds
        vm.prank(users.seller);
        wrappedLoanManagerProxy.withdrawFunds(1, users.seller, 100_000e6);

        // after balance
        uint256 poolBalanceAfter = IERC20(address(usdc)).balanceOf(address(pool));
        uint256 sellerBalanceAfter = IERC20(address(usdc)).balanceOf(users.seller);

        assertEq(poolBalanceAfter, poolBalanceBefore - 100_000e6);
        assertEq(sellerBalanceAfter, sellerBalanceBefore + 100_000e6);
    }

    function test_impairLoan() public {
        _callerDepositToReceiver(users.caller, users.receiver, 1_000_000e6);
        (uint256 newRate,) = _createLoan(100_000e6);

        vm.warp(block.timestamp + 15 days);

        vm.expectEmit(true, true, true, true);
        // after the impairment, the domainEnd is set to block.timestamp, and the issuanceRate is set to 0
        uint112 accountedInterest = uint112(newRate * 15 days / 1e27);
        emit IssuanceParamsUpdated(uint48(block.timestamp), 0, accountedInterest);

        vm.expectEmit(true, true, true, true);
        emit UnrealizedLossesUpdated(100_000e6 + accountedInterest);

        vm.expectEmit(true, true, true, true);
        emit LoanImpaired(1, block.timestamp);

        // the pool admin trigger the impairment
        vm.prank(users.pool_admin);
        wrappedLoanManagerProxy.impairLoan(1);

        // check unrealized losses
        uint256 unrealizedLosses = wrappedLoanManagerProxy.unrealizedLosses();
        assertEq(unrealizedLosses, 100_000e6 + accountedInterest);
    }

    function test_removeLoanImpairment() public {
        _callerDepositToReceiver(users.caller, users.receiver, 1_000_000e6);
        (uint256 newRate,) = _createLoan(100_000e6);

        vm.warp(block.timestamp + 15 days);

        // the pool admin trigger the impairment
        vm.prank(users.pool_admin);
        wrappedLoanManagerProxy.impairLoan(1);

        vm.warp(block.timestamp + 5 days);

        vm.expectEmit(true, true, true, true);
        emit UnrealizedLossesUpdated(0);

        vm.expectEmit(true, true, true, true);
        // also add the accrued interest in the 5 days of impairment
        // notice that the interestRate in the impaired period is the same as normal period
        uint112 accountedInterest = uint112(newRate * (15 + 5) * 1 days / 1e27);
        emit IssuanceParamsUpdated(uint48(block.timestamp + 10 days), newRate, accountedInterest);

        vm.expectEmit(true, true, true, true);
        // 30 days - (15 + 5) days = 10 days
        emit ImpairmentRemoved(1, block.timestamp + 10 days);

        // reverse the impairment
        vm.prank(users.pool_admin);
        wrappedLoanManagerProxy.removeLoanImpairment(1);

        // check unrealized losses
        uint256 unrealizedLosses = wrappedLoanManagerProxy.unrealizedLosses();
        assertEq(unrealizedLosses, 0);
    }

    function test_triggerDefault() public {
        _callerDepositToReceiver(users.caller, users.receiver, 1_000_000e6);
        (uint256 newRate, uint256 periodicInterestRate) = _createLoan(100_000e6);

        uint256 dueDate = block.timestamp + 30 days;
        
        // case1: due date < block.timestamp < due date + grace period
        vm.warp(block.timestamp + 31 days);

        vm.expectRevert(abi.encodeWithSelector(Errors.LoanManager_NotPastDueDatePlusGracePeriod.selector, 1));

        vm.prank(users.pool_admin);
        wrappedLoanManagerProxy.triggerDefault(1);

        // case2: block.timestamp > due date + grace period
        vm.warp(block.timestamp + 6 days + 100 days);

        vm.expectEmit(true, true, true, true);
        emit PrincipalOutUpdated(0);

        vm.expectEmit(true, true, true, true);
        emit IssuanceParamsUpdated(uint48(block.timestamp), 0, 0);

        vm.prank(users.pool_admin);
        (uint256 remainingLosses, uint256 protocolFee) = wrappedLoanManagerProxy.triggerDefault(1);

        // 100 days late
        uint256 fullDaysLate = ((block.timestamp - dueDate + (1 days - 1)) / 1 days) * 1 days;
        uint256 latePeriodicInterestRate = uint256(0.32e6) * (1e18 / 1e6) * fullDaysLate / 365 days; // e6 * e18 / e6 = e18

        (uint256 principal, uint256[2] memory interests) = wrappedLoanManagerProxy.getLoanPaymentDetailedBreakdown(1);

        uint256 netInterest = newRate * 30 days / 1e27;
        uint256 netLateInterest = 100_000e6 * latePeriodicInterestRate / 1e18;

        // notice that the netInterest is not the same as the interests[0] in the loan payment breakdown
        // one is calculated by the issuanceRate, the other is calculated by the periodicInterestRate
        assertEq(principal, 100_000e6);
        assertEq(interests[1], netLateInterest);
        assertEq(remainingLosses, principal + netInterest + netLateInterest);
        assertEq(protocolFee, 0);


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

    function _setAdminAndProtocolFeeRate(uint256 adminFeeRate_, uint256 protocolFeeRate_) internal {
        vm.startPrank(users.governor);
        wrappedLopoGlobalsProxy.setProtocolFeeRate(address(wrappedPoolConfiguratorProxy), protocolFeeRate_);
        changePrank(users.pool_admin);
        wrappedPoolConfiguratorProxy.setAdminFeeRate(adminFeeRate_);
        vm.stopPrank();
    }
}
