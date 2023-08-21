// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { ILopoGlobalsEvents } from "./ILopoGlobalsEvents.sol";

interface ILopoGlobals is ILopoGlobalsEvents {
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

    function riskPremiumFor(address borrower_) external view returns (uint256 riskPremium_);

    function creditExpirationFor(address borrower_) external view returns (uint256 creditExpiration_);

    function isFunctionPaused(address contract_, bytes4 sig_) external view returns (bool isFunctionPaused_);

    function isFunctionPaused(bytes4 sig_) external view returns (bool isFunctionPaused_);

    function exitFeePercent(address poolManager_) external view returns (uint256 exitFeePercent_);

    function withdrawalDurationInDays(address poolManager_) external view returns (uint256 withdrawalDurationInDays_);

    function minDepositLimit(address poolManager_) external view returns (UD60x18 minDepositLimit_);

    function minPoolLiquidityRatio() external view returns (UD60x18 minPoolLiquidityRatio_);

    function riskFreeRate() external view returns (uint256 riskFreeRate_);

    function gracePeriod() external view returns (uint256 gracePeriod_);

    function lateInterestExcessRate() external view returns (uint256 lateInterestExcessRate_);

    /**
     *  @dev    Gets governor address.
     *  @return governor_ The address of the governor.
     */
    function governor() external view returns (address governor_);

    function isReceivable(address receivable_) external view returns (bool isReceivable_);

    function isEnabled(address poolAddress_) external view returns (bool isEnabled_);

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

    function setProtocolFeeRate(address pool_, uint256 protocolFeeRate_) external;

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

    function setValidBuyer(address buyer_, bool isValid_) external;

    function setValidReceivable(address receivable_, bool isValid_) external;

    function setRiskFreeRate(uint256 riskFreeRate_) external;

    function setMinPoolLiquidityRatio(UD60x18 minPoolLiquidityRatio_) external;

    function setMinDepositLimit(address poolManager_, UD60x18 minDepositLimit_) external;

    function protocolFeeRate(address poolConfigurator_) external view returns (uint256 protocolFeeRate_);

    function setValidPoolAdmin(address poolAdmin_, bool isValid_) external;

    function setPoolConfigurator(address poolAdmin_, address poolConfigurator_) external;

    function setMinCoverAmount(address poolConfigurator_, uint256 minCover_) external;
}
