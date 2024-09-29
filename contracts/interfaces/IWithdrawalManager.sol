// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { WithdrawalManager } from "../libraries/types/DataTypes.sol";

import { IPoolAddressesProvider } from "./IPoolAddressesProvider.sol";
import { IWithdrawalManagerStorage } from "./IWithdrawalManagerStorage.sol";

interface IWithdrawalManager is IWithdrawalManagerStorage {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a withdrawal manager is initialized.
    /// @param poolAddressesProvider_ The address of the PoolAddressesProvider.
    /// @param cycleDuration_ The duration of a withdrawal cycle.
    /// @param windowDuration_ The duration of the withdrawal window.
    event Initialized(address poolAddressesProvider_, uint256 cycleDuration_, uint256 windowDuration_);

    /// @notice Emitted when the configuration of the withdrawal manager is updated.
    /// @param configId_ The id of the configuration.
    /// @param initialCycleId_ The id of the initial cycle.
    /// @param initialCycleTime_ The starting time of the initial cycle.
    /// @param cycleDuration_ The duration of a withdrawal cycle.
    /// @param windowDuration_ The duration of the withdrawal window.
    event ConfigurationUpdated(
        uint256 indexed configId_,
        uint64 initialCycleId_,
        uint64 initialCycleTime_,
        uint64 cycleDuration_,
        uint64 windowDuration_
    );

    /// @notice Emitted when a withdrawal is cancelled.
    /// @param account_ The account whose withdrawal is cancelled.
    event WithdrawalCancelled(address indexed account_);

    /// @notice Emitted when a withdrawal is processed.
    /// @param account_ The account whose withdrawal is processed.
    /// @param sharesToRedeem_ The amount of shares to redeem.
    /// @param assetsToWithdraw_ The amount of assets to withdraw.
    event WithdrawalProcessed(address indexed account_, uint256 sharesToRedeem_, uint256 assetsToWithdraw_);

    /// @notice Emitted when a withdrawal is updated.
    /// @param account_ The account whose withdrawal is updated.
    /// @param lockedShares_ The new amount of locked shares.
    /// @param windowStart_ The new starting time of the withdrawal window.
    /// @param windowEnd_ The new ending time of the withdrawal window.
    event WithdrawalUpdated(address indexed account_, uint256 lockedShares_, uint64 windowStart_, uint64 windowEnd_);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Initializes the Withdrawal Manager.
    /// @dev Function is invoked by the proxy contract when the Withdrawal Manager Contract is added to the
    /// PoolAddressesProvider of the market.
    /// @param provider_ The address of the PoolAddressesProvider.
    /// @param cycleDuration_ The total duration of a withdrawal cycle.
    /// @param windowDuration_ The duration of the withdrawal window.
    function initialize(IPoolAddressesProvider provider_, uint256 cycleDuration_, uint256 windowDuration_) external;

    /*//////////////////////////////////////////////////////////////
                    EXTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Pool admin sets a new configuration for the withdrawal manager.
    /// @param cycleDuration_ The total duration of a withdrawal cycle.
    /// @param windowDuration_  The total duration of a withdrawal window.
    function setExitConfig(uint256 cycleDuration_, uint256 windowDuration_) external;

    /// @notice Add more shares for withdrawal.
    /// @param shares_ The amount of shares to add.
    /// @param owner_ The owner of the shares.
    function addShares(uint256 shares_, address owner_) external;

    /// @notice Remove shares from withdrawal.
    /// @param shares_  The amount of shares to remove from withdrawal.
    /// @param owner_  The owner of the shares.
    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);

    /// @notice Process the exit of requested shares of a owner.
    /// @param requestedShares_  The amount of shares to redeem.
    /// @param owner_  The owner of the shares.
    /// @return redeemableShares_ The amount of redeemable shares.
    /// @return resultingAssets_ The corresponding amount of assets with the redeemable shares.
    function processExit(
        uint256 requestedShares_,
        address owner_
    )
        external
        returns (uint256 redeemableShares_, uint256 resultingAssets_);

    /*//////////////////////////////////////////////////////////////
                      EXTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Checks if the owner has a withdrawal request in the exit window.
    /// @param owner_ The owner address to check.
    /// @return isInExitWindow_ True if the owner has a withdrawal request in the exit window.
    function isInExitWindow(address owner_) external view returns (bool isInExitWindow_);

    /// @notice Gets the total amount of liquidity locked in the current cycle.
    /// @return lockedLiquidity_ The total amount of liquidity locked in the current cycle.
    function lockedLiquidity() external view returns (uint256 lockedLiquidity_);

    /// @notice Previews the amount of shares and assets that can be redeemed.
    /// @param owner_ The owner of the shares.
    /// @param shares_ The amount of shares to redeem.
    /// @return redeemableShares_ The amount of redeemable shares.
    /// @return resultingAssets_ The corresponding amount of assets with the redeemable shares.
    function previewRedeem(
        address owner_,
        uint256 shares_
    )
        external
        view
        returns (uint256 redeemableShares_, uint256 resultingAssets_);

    /*//////////////////////////////////////////////////////////////
                       PUBLIC CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Gets the configuration of a config id.
    /// @param configId_ The id of the config.
    /// @return config_ The config.
    function getCycleConfig(uint256 configId_) external view returns (WithdrawalManager.CycleConfig memory config_);

    /// @notice Gets the configuration of a given cycle id.
    /// @param cycleId_  The cycle id.
    /// @return config_ The configuration used at the cycle id.
    function getConfigAtId(uint256 cycleId_) external view returns (WithdrawalManager.CycleConfig memory config_);

    /// @notice Gets the configuration of the current cycle id.
    /// @return config_ The configuration used at the current cycle id.
    function getCurrentConfig() external view returns (WithdrawalManager.CycleConfig memory config_);

    /// @notice Gets the current cycle id.
    /// @return cycleId_ The id of the current cycle.
    function getCurrentCycleId() external view returns (uint256 cycleId_);

    /// @notice Gets the starting time of a window for a given cycle id.
    /// @param cycleId_ The id of the cycle.
    /// @return windowStart_ The starting time of the window.
    function getWindowStart(uint256 cycleId_) external view returns (uint64 windowStart_);

    /// @notice Gets the start and end time of a window for a given cycle id.
    /// @param cycleId_ The id of the cycle.
    /// @return windowStart_ The starting time of the window.
    /// @return windowEnd_ The ending time of the window.
    function getWindowAtId(uint256 cycleId_) external view returns (uint64 windowStart_, uint64 windowEnd_);

    /// @notice Gets the redeemable amount of an owner based in the current cycle.
    /// @param lockedShares_ The amount of locked shares under the owner.
    /// @param owner_ The address of the owner.
    /// @return redeemableShares_ The amount of redeemable shares.
    /// @return resultingAssets_ The corresponding amount of assets with the redeemable shares.
    function getRedeemableAmounts(
        uint256 lockedShares_,
        address owner_
    )
        external
        view
        returns (uint256 redeemableShares_, uint256 resultingAssets_);
}
