// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                    GENERICS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when `msg.sender` is not the expected one.
    error InvalidCaller(address caller, address expectedCaller);

    /// @notice Thrown when `msg.sender` is neither the pool admin nor the governor.
    error NotPoolAdminOrGovernor(address caller_);

    /// @notice Thrown when `msg.sender` is not the pool admin
    error NotPoolAdmin(address caller_);

    /// @notice Thrown when `msg.sender` is not the pool configurator
    error NotPoolConfigurator(address caller_);

    error InvalidAddressProvider(address provider, address expectedProvider);

    error ERC20TransferFailed(address asset, address from, address to, uint256 amount);

    error FunctionPaused(bytes4 sig);

    error NotBorrower(address caller);

    error ProtocolPaused();

    /*//////////////////////////////////////////////////////////////////////////
                                POOL CONFIGURATOR
    //////////////////////////////////////////////////////////////////////////*/

    error PoolConfigurator_NotConfigured();

    error PoolConfigurator_Configured();

    error PoolConfigurator_Paused();

    error PoolConfigurator_NotPoolAdminOrGovernor();

    error PoolConfigurator_ConfiguredAndNotPoolAdmin();

    error PoolConfigurator_InvalidPoolAdmin(address account);

    error PoolConfigurator_InvalidPoolAsset(address asset);

    error PoolConfigurator_IsAlreadyPoolAdmin(address account);

    error PoolConfigurator_CallerNotPendingPoolAdmin(address pendingPoolAdmin, address caller);

    error PoolConfigurator_CallerNotLoanManager(address poolManager, address caller);

    error PoolConfigurator_PoolZeroSupply();

    error PoolConfigurator_DestinationIsZero();

    error PoolConfigurator_InsufficientLiquidity();

    error PoolConfigurator_InsufficientCover();

    error PoolConfigurator_WithdrawalNotImplemented();

    error PoolConfigurator_NoAllowance(address owner, address spender);

    error PoolConfigurator_PoolApproveWithdrawalManagerFailed(uint256 amount);

    error PoolConfigurator_ERC20TransferFromFailed(address asset, address from, address to, uint256 amount);

    /*//////////////////////////////////////////////////////////////////////////
                                LOPO GLOBALS
    //////////////////////////////////////////////////////////////////////////*/

    error Globals_CallerNotPoolConfigurator(address poolConfigurator, address caller);

    error Globals_ToInvalidPoolAdmin(address poolAdmin);

    error Globals_ToInvalidPoolConfigurator(address poolConfigurator);

    error Globals_AlreadyHasConfigurator(address poolAdmin, address poolConfigurator);

    error Globals_AdminZeroAddress();

    error Globals_CallerNotGovernor(address governor, address caller);

    error Globals_CallerNotPendingGovernor(address pendingGovernor, address caller);

    error Globals_InvalidVault(address vault);

    error Globals_InvalidReceivable(address receivable);

    error Globals_RiskFreeRateGreaterThanOne(uint256 riskFreeRate);

    error Globals_MinPoolLiquidityRatioGreaterThanOne(uint256 minPoolLiquidityRatio);

    error Globals_ProtocolFeeRateGreaterThanOne(uint256 protocolFeeRate);

    /*//////////////////////////////////////////////////////////////////////////
                                LOAN MANAGER
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when `msg.sender` is not the buyer.
    error LoanManager_CallerNotBuyer(address expectedBuyer_);

    /// @notice Thrown when `msg.sender` is not the seller.
    error LoanManager_CallerNotSeller(address expectedSeller_);

    /// @notice Thrown when buyer approves an invalid receivable (either buyer or seller is not whitelisted or repayment
    /// timestamp is in the past).
    error LoanManager_InvalidReceivable(uint256 receivablesTokenId_);

    /// @notice Thrown when the buyer requests for a principal larger than the face amount of the receivable
    error LoanManager_PrincipalRequestedTooHigh(uint256 principalRequested_, uint256 maxPrincipal_);

    /// @notice Thrown when the buyer fails to repay enough to close the loan
    error LoanManager_InsufficientRepayment(uint16 loanId_, uint256 repayment_, uint256 expectedRepayment_);

    /// @notice Thrown when the seller overdraws
    error LoanManager_Overdraw(uint16 loanId_, uint256 amount_, uint256 withdrawableAmount_);

    /// @notice Thrown when the loan id is invalid
    error LoanManager_NotLoan(uint16 loanId_);

    /// @notice Thrown when the loan is already impaired
    error LoanManager_LoanImpaired(uint16 loanId_);

    /// @notice Thrown when the loan is not impaired
    error LoanManager_LoanNotImpaired(uint16 loanId_);

    /// @notice Thrown when the loan is past due date
    error LoanManager_PastDueDate(uint16 loanId_, uint256 dueDate_, uint256 currentTimestamp_);

    /*//////////////////////////////////////////////////////////////////////////
                                Receivable
    //////////////////////////////////////////////////////////////////////////*/

    error Receivable_CallerNotBuyer(address caller);

    error Receivable_CallerNotGovernor(address governor, address caller);

    error Receivable_InvalidGlobals(address globals);

    /*//////////////////////////////////////////////////////////////////////////
                                Withdrawal Manager
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the window duration set is 0
    error WithdrawalManager_ZeroWindow();

    /// @notice Thrown when the window duration set is larger than the cycle duration
    error WithdrawalManager_WindowGreaterThanCycle();

    /// @notice Thrown when the withdrawal is still pending
    error WithdrawalManager_WithdrawalPending(address owner_);

    /// @notice Thrown when the action results in no change
    error WithdrawalManager_NoOp(address owner_);

    /// @notice Thrown when the owner removes more shares than they have
    error WithdrawalManager_Overremove(address owner_, uint256 shares_, uint256 lockedShares_);

    /// @notice Thrown when the owner has no withdrawal request (that is locked shares is zero)
    error WithdrawalManager_NoRequest(address owner_);

    /// @notice Thrown when the shares a owner requests to withdraw differs from their withdrawal request
    error WithdrawalManager_InvalidShares(address owner_, uint256 requestedShares_, uint256 lockedShares_);

    /// @notice Thrown when the current time is not in the owner's withdrawal window
    error WithdrawalManager_NotInWindow(uint256 currentTimestamp_, uint256 windowStart_, uint256 windowEnd_);
}
