// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { UD60x18, ud } from "@prb/math/UD60x18.sol";

interface ILopoGlobals {
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

    event ProtocolFeeRateSet(uint256 indexed protocolFeeRate_);

    event MinDepositLimitSet(address indexed poolManager_, uint256 indexed minDepositLimit_);

    event WithdrawalDurationInDaysSet(address indexed poolManager_, uint256 indexed withdrawalDurationInDays_);

    event OwnedPoolConfiguratorSet(address indexed poolAdmin_, address indexed poolConfigurator_);

    /*//////////////////////////////////////////////////////////////////////////
                            CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function poolAdmins(address poolAdmin_) external view returns (address ownedPoolConfigurator_, bool isPoolAdmin_);

    function isPoolAdmin(address account_) external view returns (bool isPoolAdmin_);

    function ownedPoolConfigurator(address account_) external view returns (address poolConfigurator_);

    function transferOwnedPoolConfigurator(address fromPoolAdmin_, address toPoolAdmin_) external;

    function maxCoverLiquidationPercent(address poolConfigurator_)
        external
        view
        returns (uint256 maxCoverLiquidationPercent_);

    function minCoverAmount(address poolConfigurator_) external view returns (uint256 minCover_);

    function isFunctionPaused(address contract_, bytes4 sig_) external view returns (bool isFunctionPaused_);

    function isFunctionPaused(bytes4 sig_) external view returns (bool isFunctionPaused_);

    function insuranceFeePercent(address poolManager_) external view returns (uint256 insuranceFeePercent_);

    function exitFeePercent(address poolManager_) external view returns (uint256 exitFeePercent_);

    function withdrawalDurationInDays(address poolManager_) external view returns (uint256 withdrawalDurationInDays_);

    function minDepositLimit(address poolManager_) external view returns (UD60x18 minDepositLimit_);

    function protocolFeeRate() external view returns (UD60x18 protocolFeeRate_);

    function minPoolLiquidityRatio() external view returns (UD60x18 minPoolLiquidityRatio_);

    function riskFreeRate() external view returns (UD60x18 riskFreeRate_);

    /**
     *  @dev    Gets governor address.
     *  @return governor_ The address of the governor.
     */
    function governor() external view returns (address governor_);

    /**
     *  @dev    Gets the validity of a borrower.
     *  @param  borrower_   The address of the borrower to query.
     *  @return isBorrower_ A boolean indicating the validity of the borrower.
     */
    function isBorrower(address borrower_) external view returns (bool isBorrower_);

    function isReceivable(address receivable_) external view returns (bool isReceivable_);

    function isBuyer(address buyer_) external view returns (bool isBuyer_);

    /**
     *  @dev    Gets the validity of a collateral asset.
     *  @param  collateralAsset_   The address of the collateralAsset to query.
     *  @return isCollateralAsset_ A boolean indicating the validity of the collateral asset.
     */
    function isCollateralAsset(address collateralAsset_) external view returns (bool isCollateralAsset_);

    /**
     *  @dev    Gets the validity of a pool asset.
     *  @param  poolAsset_   The address of the poolAsset to query.
     *  @return isPoolAsset_ A boolean indicating the validity of the pool asset.
     */
    function isPoolAsset(address poolAsset_) external view returns (bool isPoolAsset_);

    /**
     *  @dev    Gets lopo vault address.
     *  @return lopoVault_ The address of the lopo vault.
     */
    function lopoVault() external view returns (address lopoVault_);

    /**
     *  @dev    Gets the pending governor address.
     *  @return pendingGovernor_ The address of the pending governor.
     */
    function pendingLopoGovernor() external view returns (address pendingGovernor_);

    /**
     *  @dev    Gets the status of the protocol pause.
     *  @return protocolPaused_ A boolean indicating the status of the protocol pause.
     */
    function protocolPaused() external view returns (bool protocolPaused_);

    /**
     *  @dev Accepts the governorship if the caller is the `pendingGovernor`.
     */
    function acceptLopoGovernor() external;

    /**
     *  @dev   Sets the pending governor.
     *  @param pendingGovernor_ The new pending governor.
     */
    function setPendingLopoGovernor(address pendingGovernor_) external;

    /**
     *  @dev   Sets the address of the Lopo vault.
     *  @param lopoVault_ The address of the Lopo vault.
     */
    function setLopoVault(address lopoVault_) external;

    /**
     *  @dev   Sets the protocol pause.
     *  @param protocolPaused_ A boolean indicating the status of the protocol pause.
     */
    function setProtocolPause(bool protocolPaused_) external;

    /**
     *  @dev   Sets the validity of the borrower.
     *  @param borrower_ The address of the borrower to set the validity for.
     *  @param isValid_  A boolean indicating the validity of the borrower.
     */
    function setValidBorrower(address borrower_, bool isValid_) external;

    /**
     *  @dev   Sets the validity of a collateral asset.
     *  @param collateralAsset_ The address of the collateral asset to set the validity for.
     *  @param isValid_         A boolean indicating the validity of the collateral asset.
     */
    function setValidCollateralAsset(address collateralAsset_, bool isValid_) external;

    /**
     *  @dev   Sets the validity of the pool asset.
     *  @param poolAsset_ The address of the pool asset to set the validity for.
     *  @param isValid_   A boolean indicating the validity of the pool asset.
     */
    function setValidPoolAsset(address poolAsset_, bool isValid_) external;

    function setValidReceivable(address receivable_, bool isValid_) external;

    function setValidBuyer(address buyer_, bool isValid_) external;

    function setRiskFreeRate(UD60x18 riskFreeRate_) external;

    function setMinPoolLiquidityRatio(UD60x18 minPoolLiquidityRatio_) external;

    function setProtocolFeeRate(UD60x18 protocolFeeRate_) external;

    function setMinDepositLimit(address poolManager_, UD60x18 minDepositLimit_) external;

    function setOwnedPoolConfigurator(address poolAdmin_, address poolConfigurator_) external;
}
