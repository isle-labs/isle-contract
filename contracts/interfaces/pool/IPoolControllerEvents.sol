// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IPoolControllerEvents {

    /**
     *  @dev   Emitted when cover is deposited.
     *  @param amount_ The amount of cover deposited.
     */
    event CoverDeposited(uint256 amount_);

    /**
     *  @dev   Emitted when cover is liquidated in the case of a loan defaulting.
     *  @param toTreasury_ The amount of cover sent to the Treasury.
     *  @param toPool_     The amount of cover sent to the Pool.
     */
    event CoverLiquidated(uint256 toTreasury_, uint256 toPool_);

    /**
     *  @dev   Emitted when cover is withdrawn.
     *  @param amount_ The amount of cover withdrawn.
     */
    event CoverWithdrawn(uint256 amount_);

    /**
     *  @dev   Emitted when a new management fee rate is set.
     *  @param managementFeeRate_ The amount of management fee rate.
     */
    event DelegateManagementFeeRateSet(uint256 managementFeeRate_);

    /**
     *  @dev   Emitted when a loan Controller is set as valid.
     *  @param loanController_   The address of the loan Controller.
     *  @param isLoanController_ Whether the loan Controller is valid.
     */
    event IsLoanControllerSet(address indexed loanController_, bool isLoanController_);

    /**
     *  @dev   Emitted when a new liquidity cap is set.
     *  @param liquidityCap_ The value of liquidity cap.
     */
    event LiquidityCapSet(uint256 liquidityCap_);

    /**
     *  @dev   Emitted when a new loan Controller is added.
     *  @param loanController_ The address of the new loan Controller.
     */
    event LoanControllerAdded(address indexed loanController_);

    /**
     *  @dev Emitted when a pool is open to public.
     */
    event OpenToPublic();

    /**
     *  @dev   Emitted when the pending pool delegate accepts the ownership transfer.
     *  @param previousDelegate_ The address of the previous delegate.
     *  @param newDelegate_      The address of the new delegate.
     */
    event PendingDelegateAccepted(address indexed previousDelegate_, address indexed newDelegate_);

    /**
     *  @dev   Emitted when the pending pool delegate is set.
     *  @param previousDelegate_ The address of the previous delegate.
     *  @param newDelegate_      The address of the new delegate.
     */
    event PendingDelegateSet(address indexed previousDelegate_, address indexed newDelegate_);

    /**
     *  @dev Emitted when the pool configuration is marked as complete.
     */
    event PoolConfigurationComplete();

    /**
     *  @dev   Emitted when a redemption of shares from the pool is processed.
     *  @param owner_            The owner of the shares.
     *  @param redeemableShares_ The amount of redeemable shares.
     *  @param resultingAssets_  The amount of assets redeemed.
     */
    event RedeemProcessed(address indexed owner_, uint256 redeemableShares_, uint256 resultingAssets_);

    /**
     *  @dev   Emitted when a redemption of shares from the pool is requested.
     *  @param owner_  The owner of the shares.
     *  @param shares_ The amount of redeemable shares.
     */
    event RedeemRequested(address indexed owner_, uint256 shares_);

    /**
     *  @dev   Emitted when a pool is sets to be active or inactive.
     *  @param active_ Whether the pool is active.
     */
    event SetAsActive(bool active_);

    /**
     *  @dev   Emitted when shares are removed from the pool.
     *  @param owner_  The address of the owner of the shares.
     *  @param shares_ The amount of shares removed.
     */
    event SharesRemoved(address indexed owner_, uint256 shares_);

    /**
     *  @dev   Emitted when the withdrawal Controller is set.
     *  @param withdrawalController_ The address of the withdrawal Controller.
     */
    event WithdrawalControllerSet(address indexed withdrawalController_);

    /**
     *  @dev   Emitted when withdrawal of assets from the pool is processed.
     *  @param owner_            The owner of the assets.
     *  @param redeemableShares_ The amount of redeemable shares.
     *  @param resultingAssets_  The amount of assets redeemed.
     */
    event WithdrawalProcessed(address indexed owner_, uint256 redeemableShares_, uint256 resultingAssets_);
}
