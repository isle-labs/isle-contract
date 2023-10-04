// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                    GENERICS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when `msg.sender` is not the expected one.
    error InvalidCaller(address caller, address expectedCaller);

    /// @notice Thrown when `msg.sender` is not the expected one.
    error CallerNotAdmin(address admin_, address caller_);

    /// @notice Thrown when `msg.sender` is neither the pool admin nor the governor.
    error NotPoolAdminOrGovernor(address caller_);

    /// @notice Thrown when `msg.sender` is not the pool admin
    error NotPoolAdmin(address caller_);

    /// @notice Thrown when `msg.sender` is not the pool configurator
    error NotPoolConfigurator(address caller_);

    error InvalidAddressesProvider(address provider, address expectedProvider);

    error ERC20TransferFailed(address asset, address from, address to, uint256 amount);

    error FunctionPaused(bytes4 sig);

    error ProtocolPaused();

    /*//////////////////////////////////////////////////////////////////////////
                                POOL CONFIGURATOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the pool admin set is not on the whitelist
    error PoolConfigurator_InvalidPoolAdmin(address poolAdmin_);

    /// @notice Thrown when the pool admin set is already owned another pool configurator
    error PoolConfigurator_AlreadyOwnsConfigurator(address poolAdmin_, address poolConfigurator_);

    /// @notice Thrown when the asset set is not on the whitelist
    error PoolConfigurator_InvalidPoolAsset(address asset_);

    /// @notice Thrown when `msg.sender` is not the loan manager
    error PoolConfigurator_CallerNotLoanManager(address expectedCaller_, address caller_);

    /// @notice Thrown when caller is not pool admin or governor
    error PoolConfigurator_CallerNotPoolAdminOrGovernor(address caller_);

    /// @notice Thrown when the total supply of the pool is zero
    error PoolConfigurator_PoolSupplyZero();

    /// @notice Thrown when the pool cover is insufficient
    error PoolConfigurator_InsufficientCover();

    /// @notice Thrown when the pool has insufficient liquidity to fund new loans
    error PoolConfigurator_InsufficientLiquidity();

    /// @notice Thrown when the spender has no allowance from the owner
    error PoolConfigurator_NoAllowance(address owner_, address spender_);

    /// @notice Thrown when the pool fails to approve the withdrawal manager with the amount of shares
    error PoolConfigurator_PoolApproveWithdrawalManagerFailed(uint256 amount_);

    /// @notice Thrown when the pool admin fails to deposit cover
    error PoolConfigurator_DepositCoverFailed(address caller_, uint256 amount_);

    /// @notice Thrown when the pool admin fails to withdraw cover
    error PoolConfigurator_WithdrawCoverFailed(address recipient_, uint256 amount_);

    /// @notice Thrown when the pool configurator is paused
    error PoolConfigurator_Paused();

    /*//////////////////////////////////////////////////////////////////////////
                                LOPO GLOBALS
    //////////////////////////////////////////////////////////////////////////*/

    error Globals_CallerNotPoolConfigurator(address poolConfigurator, address caller);

    error Globals_ToInvalidPoolAdmin(address poolAdmin);

    error Globals_ToInvalidPoolConfigurator(address poolConfigurator);

    error Globals_AlreadyOwnsConfigurator(address poolAdmin, address poolConfigurator);

    error Globals_AdminZeroAddress();

    error Globals_CallerNotGovernor(address governor, address caller);

    error Globals_CallerNotPendingGovernor(address pendingGovernor, address caller);

    error Globals_InvalidVault(address vault);

    error Globals_InvalidReceivable(address receivable);

    error Globals_RiskFreeRateGreaterThanOne(uint256 riskFreeRate);

    error Globals_MinPoolLiquidityRatioGreaterThanOne(uint256 minPoolLiquidityRatio);

    error Globals_protocolFeeGreaterThanOne(uint256 protocolFee);

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

    error LoanManager_CollateralAssetNotAllowed(address collateralAsset_);

    error LoanManager_NotPastDueDatePlusGracePeriod(uint16 loanId_);

    error LoanManager_CallerNotReceivableBuyer(address expectedBuyer_);

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

    /*//////////////////////////////////////////////////////////////////////////
                                    Pool
    //////////////////////////////////////////////////////////////////////////*/

    error Pool_ZeroAsset();

    error Pool_ZeroConfigurator();

    error Pool_FailedApprove();

    error Pool_RecipientZeroAddress();

    error Pool_DepositGreaterThanMax(uint256 assets, uint256 maxDeposit);

    error Pool_MintGreaterThanMax(uint256 shares, uint256 maxMint);

    error Pool_InsufficientPermit(uint256 assets, uint256 permits);

    error Pool_RedeemMoreThanMax(uint256 shares, uint256 maxRedeem);

    error Pool_WithdrawalNotImplemented();
}
