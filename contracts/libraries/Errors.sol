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

    error Globals_CallerNotGovernor(address governor, address caller);

    error Globals_CallerNotPendingGovernor(address pendingGovernor, address caller);

    error Globals_InvalidVault(address vault);

    error Globals_InvalidReceivable(address receivable);

    error Globals_RiskFreeRateGreaterThanOne(uint256 riskFreeRate);

    error Globals_MinPoolLiquidityRatioGreaterThanOne(uint256 minPoolLiquidityRatio);

    error Globals_ProtocolFeeRateGreaterThanOne(uint256 protocolFeeRate);

    error Globals_AlreadyHasPoolConfigurator(address poolAdmin, address poolConfigurator);

    /*//////////////////////////////////////////////////////////////////////////
                                Receivable
    //////////////////////////////////////////////////////////////////////////*/

    error Receivable_CallerNotBuyer(address caller);

    error Receivable_CallerNotGovernor(address governor, address caller);

    error Receivable_InvalidGlobals(address globals);
}
