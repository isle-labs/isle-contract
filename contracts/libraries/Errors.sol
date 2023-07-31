// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                    GENERICS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when `msg.sender` is not the admin.
    error InvalidCaller(address caller, address expectedCaller);

    error InvalidAddressProvider(address provider, address expectedProvider);

    error ERC20TransferFailed(address asset, address from, address to, uint256 amount);

    error FunctionPaused(bytes4 sig);

    error NotPoolAdminOrGovernor(address caller);

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

    /*//////////////////////////////////////////////////////////////////////////
                                LOPO GLOBALS
    //////////////////////////////////////////////////////////////////////////*/

    error Globals_CallerNotPoolConfigurator(address poolConfigurator, address caller);

    error Globals_ToInvalidPoolAdmin(address poolAdmin);

    error Globals_AlreadyHasConfigurator(address poolAdmin, address poolConfigurator);

    error Globals_AdminZeroAddress();

    /*//////////////////////////////////////////////////////////////////////////
                                LOAN MANAGER
    //////////////////////////////////////////////////////////////////////////*/

    error LoanManager_LoanInactive(uint16 loanId);
    error LoanManager_NotLoan(uint16 loanId);
    error LoanManager_PoolFundsTransferFailed();
    error LoanManager_PoolAdminFundsTransferFailed();
    error LoanManager_VaultFundsTransferFailed();
    error LoanManager_BorrowerFundsTransferFailed();
    error LoanManager_FundsTransferFailed();
    error LoanManager_LoanImpaired(uint16 loanId);
    error LoanManager_NotAuthorizedToRemoveLoanImpairment(uint16 loanId);
    error LoanManager_PastDueDate(uint16 loanId_);
    error LoanManager_NotImpaired(uint16 loanId_);
    error LoanManager_NotCorrectBorrower(uint16 loanId_, address expectedBorrower_);
    error LoanManager_DrawableFundsDecreased(uint16 loanId_);
    error LoanManager_InsufficientPayment(uint16 loanId_);
    error LoanManager_BorrowerCreditExpired(address borrower_, uint256 expirationTimestamp_);
    error LoanManager_InsufficientFunds(uint16 loanId_);
    error LoanManager_NotBuyerOrSeller();
}
