// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IWithdrawalManager {

    struct CycleConfig {
        uint64 initialCycleId;
        uint64 initialCycleTime;
        uint64 cycleDuration;
        uint64 windowDuration;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event Initialized(address poolAddressesProvider_, uint256 cycleDuration_, uint256 windowDuration_);

    event ConfigurationUpdated(uint256 indexed configId_, uint64 initialCycleId_, uint64 initialCycleTime_, uint64 cycleDuration_, uint64 windowDuration_);

    event WithdrawalCancelled(address indexed account_);

    event WithdrawalProcessed(address indexed account_, uint256 sharesToRedeem_, uint256 assetsToWithdraw_);

    event WithdrawalUpdated(address indexed account_, uint256 lockedShares_, uint64 windowStart_, uint64 windowEnd_);

    /*//////////////////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    function cycleConfigs(uint256 configId_) external returns (uint64 initialCycleId_, uint64 initialCycleTime_, uint64 cycleDuration_, uint64 windowDuration_);

    function exitCycleId(address account_) external view returns (uint256 cycleId_);

    function latestConfigId() external view returns (uint256 configId_);

    function lockedShares(address account_) external view returns (uint256 lockedShares_);

    function poolAddressesProvider() external view returns (address poolAddressesProvider_);

    function totalCycleShares(uint256 cycleId_) external view returns (uint256 totalCycleShares_);

    /*//////////////////////////////////////////////////////////////////////////
                            CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function asset() external view returns (address asset_);

    function getConfigAtId(uint256 cycleId_) external view returns (CycleConfig memory config_);

    function getCurrentConfig() external view returns (CycleConfig memory config_);

    function getCurrentCycleId() external view returns (uint256 cycleId_);

    function getRedeemableAmounts(uint256 lockedShares_, address owner_) external view returns (uint256 redeemableShares_, uint256 resultingAssets_, bool partialLiquidity_);

    function getWindowStart(uint256 cycleId_) external view returns (uint256 windowStart_);

    function getWindowAtId(uint256 cycleId_) external view returns (uint256 windowStart_, uint256 windowEnd_);

    function isInExitWindow(address owner_) external view returns (bool isInExitWindow_);

    function lockedLiquidity() external view returns (uint256 lockedLiquidity_);

    function previewRedeem(
        address owner_,
        uint256 shares_
    )
        external
        view
        returns (uint256 redeemableShares_, uint256 resultingAssets_);

    function previewWithdraw(
        address owner_,
        uint256 assets_
    )
        external
        view
        returns (uint256 redeemableAssets_, uint256 resultingShares_);

    /*//////////////////////////////////////////////////////////////////////////
                            NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function initConfig(uint256 cycleDuration_, uint256 windowDuration_) external;

    function addShares(uint256 shares_, address owner_) external;

    function processExit(
        uint256 requestedShares_,
        address owner_
    )
        external
        returns (uint256 redeemableShares_, uint256 resultingAssets_);

    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);

    function setExitConfig(uint256 cycleDuration_, uint256 windowDuration_) external;

}
