// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                    GENERICS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when `msg.sender` is not the admin.
    error InvalidCaller(address caller, address expectedCaller);

    /// @notice Thrown when `msg.sender` is neither the pool admin nor the governor.
    error NotPoolAdminOrGovernor(address caller_);

    error InvalidAddressProvider(address provider, address expectedProvider);

    error ERC20TransferFailed(address asset, address from, address to, uint256 amount);

    error FunctionPaused(bytes4 sig);

    error NotPoolAdmin(address caller);

    error NotBorrower(address caller);

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
}
