// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface ILopoGlobalsEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event Initialized();
    event PoolConfiguratorOwnershipTransferred(
        address indexed fromPoolAdmin_, address indexed toPoolAdmin_, address indexed PoolConfigurator_
    );

    /**
     *  @dev   The governorship has been accepted.
     *  @param previousGovernor_ The previous governor.
     *  @param currentGovernor_  The new governor.
     */
    event GovernorshipAccepted(address indexed previousGovernor_, address indexed currentGovernor_);

    /**
     *  @dev   The address for the Lopo vault has been set.
     *  @param previousLopoVault_ The previous vault.
     *  @param currentLopoVault_  The new vault.
     */
    event LopoVaultSet(address indexed previousLopoVault_, address indexed currentLopoVault_);

    /**
     *  @dev   The max liquidation percent for the given pool manager has been set.
     *  @param poolManager_                The address of the pool manager.
     *  @param maxCoverLiquidationPercent_ The new value for the cover liquidation percent.
     */
    event MaxCoverLiquidationPercentSet(address indexed poolManager_, uint256 maxCoverLiquidationPercent_);

    /**
     *  @dev   The minimum cover amount for the given pool manager has been set.
     *  @param poolManager_    The address of the pool manager.
     *  @param minCoverAmount_ The new value for the minimum cover amount.
     */
    event MinCoverAmountSet(address indexed poolManager_, uint256 minCoverAmount_);

    /**
     *  @dev   The pending governor has been set.
     *  @param pendingGovernor_ The new pending governor.
     */
    event PendingGovernorSet(address indexed pendingGovernor_);

    /**
     *  @dev   The ownership of the pool manager was transferred.
     *  @param fromPoolDelegate_ The address of the previous pool delegate.
     *  @param toPoolDelegate_   The address of the new pool delegate.
     *  @param poolManager_      The address of the pool manager.
     */
    event PoolManagerOwnershipTransferred(
        address indexed fromPoolDelegate_, address indexed toPoolDelegate_, address indexed poolManager_
    );

    /**
     *  @dev   The protocol pause was set to a new state.
     *  @param caller_         The address of the security admin or governor that performed the action.
     *  @param protocolPaused_ The protocol paused state.
     */
    event ProtocolPauseSet(address indexed caller_, bool protocolPaused_);

    /**
     *  @dev   A valid borrower was set.
     *  @param borrower_ The address of the borrower.
     *  @param isValid_  The validity of the borrower.
     */
    event ValidBorrowerSet(address indexed borrower_, bool isValid_);

    /**
     *  @dev   A valid asset was set.
     *  @param collateralAsset_ The address of the collateral asset.
     *  @param isValid_         The validity of the collateral asset.
     */
    event ValidCollateralAssetSet(address indexed collateralAsset_, bool isValid_);

    /**
     *  @dev   A valid asset was set.
     *  @param poolAsset_ The address of the asset.
     *  @param isValid_   The validity of the asset.
     */
    event ValidPoolAssetSet(address indexed poolAsset_, bool isValid_);

    /**
     *  @dev   A valid receivable was set.
     *  @param receivable_ The address of the receivable.
     *  @param isValid_    The validity of the receivable.
     */
    event ValidReceivableSet(address indexed receivable_, bool isValid_);

    event ValidBuyerSet(address indexed buyer_, bool isValid_);

    event RiskFreeRateSet(uint256 indexed riskFreeRate_);

    event MinPoolLiquidityRatioSet(uint256 indexed minPoolLiquidityRatio_);

    event ProtocolFeeRateSet(address indexed pool_, uint256 indexed protocolFeeRate_);

    event MinDepositLimitSet(address indexed poolManager_, uint256 indexed minDepositLimit_);

    event WithdrawalDurationInDaysSet(address indexed poolManager_, uint256 indexed withdrawalDurationInDays_);

    event ValidPoolAdminSet(address indexed poolAdmin_, bool isValid_);

    event PoolConfiguratorSet(address indexed poolAdmin_, address indexed poolConfigurator_);
}
