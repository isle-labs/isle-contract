// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

library Errors {
    /*//////////////////////////////////////////////////////////////
                                GENERICS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when `msg.sender` is not the expected one.
    error InvalidCaller(address caller, address expectedCaller);

    /// @notice Thrown when `msg.sender` is not the governor.
    error CallerNotGovernor(address governor_, address caller_);

    /// @notice Thrown when `msg.sender` is neither the pool admin nor the governor.
    error NotPoolAdminOrGovernor(address caller_);

    /// @notice Thrown when `msg.sender` is not the pool admin.
    error NotPoolAdmin(address caller_);

    /// @notice Thrown when `msg.sender` is not the pool configurator.
    error NotPoolConfigurator(address caller_);

    error InvalidAddressesProvider(address provider, address expectedProvider);

    error FunctionPaused(bytes4 sig);

    error ProtocolPaused();

    /// @notice Thrown when pool addresses provider is set to 0.
    error AddressesProviderZeroAddress();

    /// @notice Thrown when the new governor is zero address.
    error GovernorZeroAddress();

    /// @notice Thrown when the address is zero address.
    error ZeroAddress();

    /// @notice Thrown when a reentrancy lock is already set.
    error ReentrancyGuardReentrantCall();

    /*//////////////////////////////////////////////////////////////
                           POOL CONFIGURATOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the pool admin set is not on the whitelist.
    error PoolConfigurator_InvalidPoolAdmin(address poolAdmin_);

    /// @notice Thrown when the asset set is not on the whitelist.
    error PoolConfigurator_InvalidPoolAsset(address asset_);

    /// @notice Thrown when `msg.sender` is not the loan manager.
    error PoolConfigurator_CallerNotLoanManager(address expectedCaller_, address caller_);

    /// @notice Thrown when caller is not pool admin or governor.
    error PoolConfigurator_CallerNotPoolAdminOrGovernor(address caller_);

    /// @notice Thrown when caller is not pool admin.
    error PoolConfigurator_CallerNotPoolAdmin(address caller_);

    /// @notice Thrown when caller is not governor.
    error PoolConfigurator_CallerNotGovernor(address caller_);

    /// @notice Thrown when the total supply of the pool is zero.
    error PoolConfigurator_PoolSupplyZero();

    /// @notice Thrown when the pool cover is insufficient.
    error PoolConfigurator_InsufficientCover();

    /// @notice Thrown when the pool has insufficient liquidity to fund new loans.
    error PoolConfigurator_InsufficientLiquidity();

    /// @notice Thrown when the spender has no allowance from the owner.
    error PoolConfigurator_NoAllowance(address owner_, address spender_);

    /// @notice Thrown when the pool fails to approve the withdrawal manager with the amount of shares.
    error PoolConfigurator_PoolApproveWithdrawalManagerFailed(uint256 amount_);

    /// @notice Thrown when the pool configurator is paused.
    error PoolConfigurator_Paused();

    /*//////////////////////////////////////////////////////////////
                        POOL ADDRESSES PROVIDER
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when IsleGlobals is set to 0.
    error PoolAddressesProvider_InvalidGlobals(address globals);

    /*//////////////////////////////////////////////////////////////
                              ISLE GLOBALS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when vault is set to 0.
    error Globals_InvalidVault(address vault);

    /// @notice Thrown when the caller is not penging governor
    error Globals_CallerNotPendingGovernor(address pendingGovernor_);

    /*//////////////////////////////////////////////////////////////
                              LOAN MANAGER
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when buyer approves an invalid receivable (either buyer or seller is not whitelisted or repayment
    /// timestamp is in the past).
    error LoanManager_InvalidReceivable(uint256 receivablesTokenId_);

    /// @notice Thrown when the buyer requests for a principal larger than the face amount of the receivable.
    error LoanManager_PrincipalRequestedTooHigh(uint256 principalRequested_, uint256 maxPrincipal_);

    /// @notice Thrown when the seller overdraws.
    error LoanManager_Overdraw(uint16 loanId_, uint256 amount_, uint256 withdrawableAmount_);

    /// @notice Thrown when the loan id is invalid.
    error LoanManager_NotLoan(uint16 loanId_);

    /// @notice Thrown when the loan is already impaired.
    error LoanManager_LoanImpaired(uint16 loanId_);

    /// @notice Thrown when the loan is not impaired.
    error LoanManager_LoanNotImpaired(uint16 loanId_);

    /// @notice Thrown when the loan is past due date.
    error LoanManager_PastDueDate(uint16 loanId_, uint256 dueDate_, uint256 currentTimestamp_);

    /// @notice Thrown when the receivable asset is not allowed.
    error LoanManager_ReceivableAssetNotAllowed(address receivableAsset_);

    /// @notice Thrown when current time is not past due date plus grace period.
    error LoanManager_NotPastDueDatePlusGracePeriod(uint16 loanId_);

    /// @notice Thrown when `msg.sender` is not the buyer.
    error LoanManager_CallerNotReceivableBuyer(address expectedBuyer_);

    /// @notice Thrown when an asset address is set to 0 for a loan manager.
    error LoanManager_AssetZeroAddress();

    /// @notice Thrown when the seller withraw fund before the loan be funded.
    error LoanManager_LoanNotFunded();

    /*//////////////////////////////////////////////////////////////
                           WITHDRAWAL MANAGER
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when the window duration set is 0.
    error WithdrawalManager_ZeroWindow();

    /// @notice Thrown when the window duration set is larger than the cycle duration.
    error WithdrawalManager_WindowGreaterThanCycle();

    /// @notice Thrown when the withdrawal is still pending.
    error WithdrawalManager_WithdrawalPending(address owner_);

    /// @notice Thrown when the action results in no change.
    error WithdrawalManager_NoOp(address owner_);

    /// @notice Thrown when the owner removes more shares than they have.
    error WithdrawalManager_Overremove(address owner_, uint256 shares_, uint256 lockedShares_);

    /// @notice Thrown when the owner has no withdrawal request (that is locked shares is zero).
    error WithdrawalManager_NoRequest(address owner_);

    /// @notice Thrown when the shares a owner requests to withdraw differs from their withdrawal request.
    error WithdrawalManager_InvalidShares(address owner_, uint256 requestedShares_, uint256 lockedShares_);

    /// @notice Thrown when the current time is not in the owner's withdrawal window.
    error WithdrawalManager_NotInWindow(uint256 currentTimestamp_, uint256 windowStart_, uint256 windowEnd_);

    /*//////////////////////////////////////////////////////////////
                                  POOL
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when an asset address is 0.
    error Pool_ZeroAsset();

    /// @notice Thrown when pool configurator address is set to 0.
    error Pool_ZeroConfigurator();

    /// @notice Thrown when the asset fails to approve the pool configurator with max amount.
    error Pool_FailedApprove();

    /// @notice Thrown when the receiver address is 0.
    error Pool_RecipientZeroAddress();

    /// @notice Thrown when the deposit amount is greater than the max deposit.
    error Pool_DepositGreaterThanMax(uint256 assets, uint256 maxDeposit);

    /// @notice Thrown when the mint amount is greater than the max mint.
    error Pool_MintGreaterThanMax(uint256 shares, uint256 maxMint);

    /// @notice Thrown when the assets is greater than the max amount to deposit.
    error Pool_InsufficientPermit(uint256 assets, uint256 permits);

    /// @notice Thrown when the redeem shares is greater than the max redeem amount.
    error Pool_RedeemMoreThanMax(uint256 shares, uint256 maxRedeem);

    /// @notice Thrown when anyone calls the `previewWithdraw` function.
    error Pool_WithdrawalNotImplemented();
}
