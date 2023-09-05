// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { console2 } from "@forge-std/console2.sol";

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { VersionedInitializable } from "./libraries/upgradability/VersionedInitializable.sol";
import { Errors } from "./libraries/Errors.sol";

import { IWithdrawalManager } from "./interfaces/IWithdrawalManager.sol";
import { IPoolConfigurator } from "./interfaces/IPoolConfigurator.sol";
import { IPoolAddressesProvider } from "./interfaces/IPoolAddressesProvider.sol";
import { IPool } from "./interfaces/IPool.sol";
import { ILopoGlobals } from "./interfaces/ILopoGlobals.sol";

import { WithdrawalManagerStorage } from "./WithdrawalManagerStorage.sol";

contract WithdrawalManager is WithdrawalManagerStorage, IWithdrawalManager, VersionedInitializable {
    using SafeCast for uint256;
    using SafeCast for uint64;
    using SafeERC20 for IERC20;

    uint256 public constant WITHDRAWAL_MANAGER_REVISION = 0x1;

    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    /*//////////////////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier onlyPoolAdmin() {
        _revertIfNotPoolAdmin();
        _;
    }

    modifier onlyPoolConfigurator() {
        _revertIfNotPoolConfigurator();
        _;
    }

    modifier whenProtocolNotPaused() {
        if (ILopoGlobals(_globals()).protocolPaused()) {
            revert Errors.ProtocolPaused();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc VersionedInitializable
    function getRevision() internal pure virtual override returns (uint256 revision_) {
        revision_ = WITHDRAWAL_MANAGER_REVISION;
    }

    constructor(IPoolAddressesProvider provider) {
        ADDRESSES_PROVIDER = provider;
    }

    /// @inheritdoc IWithdrawalManager
    function initialize(
        IPoolAddressesProvider provider_,
        uint256 cycleDuration_,
        uint256 windowDuration_
    )
        external
        override
        initializer
    {
        if (ADDRESSES_PROVIDER != provider_) {
            revert Errors.InvalidAddressProvider({
                expectedProvider: address(ADDRESSES_PROVIDER),
                provider: address(provider_)
            });
        }

        cycleConfigs[0] = CycleConfig({
            initialCycleId: 1,
            initialCycleTime: uint64(block.timestamp),
            cycleDuration: uint64(cycleDuration_),
            windowDuration: uint64(windowDuration_)
        });

        emit Initialized(address(provider_), cycleDuration_, windowDuration_);

        emit ConfigurationUpdated({
            configId_: 0,
            initialCycleId_: 1,
            initialCycleTime_: uint64(block.timestamp),
            cycleDuration_: uint64(cycleDuration_),
            windowDuration_: uint64(windowDuration_)
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IWithdrawalManager
    function setExitConfig(uint256 cycleDuration_, uint256 windowDuration_) external override whenProtocolNotPaused {
        if (msg.sender != _poolAdmin()) {
            revert Errors.NotPoolAdmin({ caller_: msg.sender });
        }

        if (windowDuration_ == 0) {
            revert Errors.WithdrawalManager_ZeroWindow();
        }

        if (windowDuration_ > cycleDuration_) {
            revert Errors.WithdrawalManager_WindowGreaterThanCycle();
        }

        // The new config will only take effect after the current cycle and two additional ones elapse.
        // This is done in order to prevent overlaps between the current and new withdrawal cycles.
        uint256 currentCycleId_ = getCurrentCycleId();
        uint256 initialCycleId_ = currentCycleId_ + 3;
        uint256 initialCycleTime_ = getWindowStart(currentCycleId_);
        uint256 latestConfigId_ = latestConfigId;

        // This isn't the most optimal way to do this, since the internal function `getConfigAt` iterates through
        // configs.
        // But this function should only be called by the pool delegate and not often, and, at most, we need to iterate
        // through 3 cycles.
        for (uint256 i = currentCycleId_; i < initialCycleId_; i++) {
            CycleConfig memory config = getConfigAtId(i);
            initialCycleTime_ += config.cycleDuration;
        }

        // if the new config takes effect on the same cycle as the latest config, overwrite it. Otherwise create a new
        // config.
        if (initialCycleId_ != cycleConfigs[latestConfigId_].initialCycleId) {
            latestConfigId_ = ++latestConfigId;
        }

        cycleConfigs[latestConfigId_] = CycleConfig({
            initialCycleId: uint64(initialCycleId_),
            initialCycleTime: uint64(initialCycleTime_),
            cycleDuration: uint64(cycleDuration_),
            windowDuration: uint64(windowDuration_)
        });

        emit ConfigurationUpdated({
            configId_: latestConfigId_,
            initialCycleId_: uint64(initialCycleId_),
            initialCycleTime_: uint64(initialCycleTime_),
            cycleDuration_: uint64(cycleDuration_),
            windowDuration_: uint64(windowDuration_)
        });
    }

    /// @inheritdoc IWithdrawalManager
    function addShares(uint256 shares_, address owner_) external override onlyPoolConfigurator {
        uint256 exitCycleId_ = exitCycleId[owner_];
        uint256 lockedShares_ = lockedShares[owner_];

        if (lockedShares_ != 0 && block.timestamp < getWindowStart(exitCycleId_)) {
            revert Errors.WithdrawalManager_WithdrawalPending({ owner_: owner_ });
        }

        // Remove all existing shares from the current cycle
        totalCycleShares[exitCycleId_] -= lockedShares_;

        lockedShares_ += shares_;

        if (lockedShares_ == 0) {
            revert Errors.WithdrawalManager_NoOp({ owner_: owner_ });
        }

        // Move all shares to the new cycle
        exitCycleId_ = getCurrentCycleId() + 2;
        totalCycleShares[exitCycleId_] += lockedShares_;

        exitCycleId[owner_] = exitCycleId_;
        lockedShares[owner_] = lockedShares_;

        IERC20(_pool()).safeTransferFrom(msg.sender, address(this), shares_);

        _emitUpdate(owner_, lockedShares_, exitCycleId_);
    }

    /// @inheritdoc IWithdrawalManager
    function removeShares(
        uint256 shares_,
        address owner_
    )
        external
        override
        onlyPoolConfigurator
        returns (uint256 sharesReturned_)
    {
        uint256 exitCycleId_ = exitCycleId[owner_];
        uint256 lockedShares_ = lockedShares[owner_];

        if (block.timestamp < getWindowStart(exitCycleId_)) {
            revert Errors.WithdrawalManager_WithdrawalPending(owner_);
        }

        if (shares_ >= lockedShares_) {
            revert Errors.WithdrawalManager_Overremove(owner_, shares_, lockedShares_);
        }

        // Remove shares from the old cycle
        totalCycleShares[exitCycleId_] -= lockedShares_;

        // Calculate remaining shares and new cycle if applicable
        lockedShares_ -= shares_;
        exitCycleId_ = lockedShares_ != 0 ? getCurrentCycleId() + 2 : 0;

        // Add shares to a new cycle if applicable
        if (lockedShares_ != 0) {
            totalCycleShares[exitCycleId_] += lockedShares_;
        }

        // Update withdrawal request
        exitCycleId[owner_] = exitCycleId_;
        lockedShares[owner_] = lockedShares_;

        sharesReturned_ = shares_;

        IERC20(_pool()).safeTransfer(owner_, shares_);

        _emitUpdate(owner_, lockedShares_, exitCycleId_);
    }

    /// @inheritdoc IWithdrawalManager
    function processExit(
        uint256 requestedShares_,
        address owner_
    )
        external
        override
        onlyPoolConfigurator
        returns (uint256 redeemableShares_, uint256 resultingAssets_)
    {
        uint256 exitCycleId_ = exitCycleId[owner_];
        uint256 lockedShares_ = lockedShares[owner_];

        if (lockedShares_ == 0) {
            revert Errors.WithdrawalManager_NoRequest(owner_);
        }

        if (requestedShares_ != lockedShares_) {
            revert Errors.WithdrawalManager_InvalidShares(owner_, requestedShares_, lockedShares_);
        }

        bool partialLiquidity_;

        (uint256 windowStart_, uint256 windowEnd_) = getWindowAtId(exitCycleId_);

        if (block.timestamp < windowStart_ || block.timestamp >= windowEnd_) {
            revert Errors.WithdrawalManager_NotInWindow(block.timestamp, windowStart_, windowEnd_);
        }

        (redeemableShares_, resultingAssets_, partialLiquidity_) = getRedeemableAmounts(lockedShares_, owner_);

        // Transfer redeemable shares back to the owner in order to be burned in the pool, re-lock remaining shares
        IERC20(_pool()).transfer(owner_, redeemableShares_);

        totalCycleShares[exitCycleId_] -= lockedShares_;

        lockedShares_ -= redeemableShares_;

        // If there are any remaining shares, move them to the next cycle
        // In case of partial liquidity, move shares only one cycle forward (instead of two)
        if (lockedShares_ != 0) {
            exitCycleId_ = getCurrentCycleId() + (partialLiquidity_ ? 1 : 2);
            totalCycleShares[exitCycleId_] += lockedShares_;
        } else {
            exitCycleId_ = 0; // User without exit cycle id has no withdrawal request
        }

        // Update the withdrawal request
        exitCycleId[owner_] = exitCycleId_;
        lockedShares[owner_] = lockedShares_;

        _emitProcess(owner_, redeemableShares_, resultingAssets_);
        _emitUpdate(owner_, lockedShares_, exitCycleId_);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IWithdrawalManager
    function isInExitWindow(address owner_) external view override returns (bool isInExitWindow_) {
        uint256 exitCycleId_ = exitCycleId[owner_];

        if (exitCycleId_ == 0) return false; // No withdrawal request

        (uint256 windowStart_, uint256 windowEnd_) = getWindowAtId(exitCycleId_);

        isInExitWindow_ = block.timestamp >= windowStart_ && block.timestamp < windowEnd_;
    }

    /// @inheritdoc IWithdrawalManager
    function lockedLiquidity() external view override returns (uint256 lockedLiquidity_) {
        uint256 currentCycleId_ = getCurrentCycleId();

        (uint256 windowStart_, uint256 windowEnd_) = getWindowAtId(currentCycleId_);

        if (block.timestamp >= windowStart_ && block.timestamp < windowEnd_) {
            IPoolConfigurator poolConfigurator_ = IPoolConfigurator(_poolConfigurator());

            uint256 totalAssetsWithLosses_ = poolConfigurator_.totalAssets() - poolConfigurator_.unrealizedLosses();
            uint256 totalSupply_ = IPool(_pool()).totalSupply();

            lockedLiquidity_ = totalCycleShares[currentCycleId_] * totalAssetsWithLosses_ / totalSupply_;
        }
    }

    /// @inheritdoc IWithdrawalManager
    function previewRedeem(
        address owner_,
        uint256 shares_
    )
        external
        view
        override
        returns (uint256 redeemableShares_, uint256 resultingAssets_)
    {
        uint256 lockedShares_ = lockedShares[owner_];

        if (shares_ != lockedShares_ || shares_ == 0) {
            return (redeemableShares_, resultingAssets_);
        }

        uint256 exitCycleId_ = exitCycleId[owner_];

        (uint256 windowStart_, uint256 windowEnd_) = getWindowAtId(exitCycleId_);

        if (block.timestamp < windowStart_ || block.timestamp >= windowEnd_) {
            return (redeemableShares_, resultingAssets_);
        }

        (redeemableShares_, resultingAssets_,) = getRedeemableAmounts(lockedShares_, owner_);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PUBLIC CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IWithdrawalManager
    function getConfigAtId(uint256 cycleId_) public view override returns (CycleConfig memory config_) {
        uint256 configId_ = latestConfigId;

        if (configId_ == 0) {
            return cycleConfigs[configId_];
        }

        while (cycleId_ < cycleConfigs[configId_].initialCycleId) {
            --configId_;
        }

        config_ = cycleConfigs[configId_];
    }

    /// @inheritdoc IWithdrawalManager
    function getCurrentConfig() public view override returns (CycleConfig memory config_) {
        uint256 configId_ = latestConfigId;

        while (block.timestamp < cycleConfigs[configId_].initialCycleTime) {
            --configId_;
        }

        config_ = cycleConfigs[configId_];
    }

    /// @inheritdoc IWithdrawalManager
    function getCurrentCycleId() public view override returns (uint256 cycleId_) {
        CycleConfig memory config_ = getCurrentConfig();
        cycleId_ = config_.initialCycleId + ((block.timestamp - config_.initialCycleTime) / config_.cycleDuration);
    }

    /// @inheritdoc IWithdrawalManager
    function getWindowStart(uint256 cycleId_) public view override returns (uint256 windowStart_) {
        CycleConfig memory config_ = getConfigAtId(cycleId_);

        windowStart_ = config_.initialCycleTime + ((cycleId_ - config_.initialCycleId) * config_.cycleDuration);
    }

    /// @inheritdoc IWithdrawalManager
    function getWindowAtId(uint256 cycleId_) public view override returns (uint256 windowStart_, uint256 windowEnd_) {
        CycleConfig memory config_ = getConfigAtId(cycleId_);

        windowStart_ = config_.initialCycleTime + (cycleId_ - config_.initialCycleId) * config_.cycleDuration;
        windowEnd_ = windowStart_ + config_.windowDuration;
    }

    function getRedeemableAmounts(
        uint256 lockedShares_,
        address owner_
    )
        public
        view
        override
        returns (uint256 redeemableShares_, uint256 resultingAssets_, bool partialLiquidity_)
    {
        IPoolConfigurator poolConfigurator_ = IPoolConfigurator(_poolConfigurator());

        uint256 availableLiquidity_ = IERC20(_asset()).balanceOf(_pool());
        uint256 totalAssetsWithLosses_ = poolConfigurator_.totalAssets() - poolConfigurator_.unrealizedLosses();
        uint256 totalSupply_ = IPool(_pool()).totalSupply();
        uint256 totalRequestedLiquidity_ = totalCycleShares[exitCycleId[owner_]] * totalAssetsWithLosses_ / totalSupply_;

        partialLiquidity_ = availableLiquidity_ < totalRequestedLiquidity_;

        // Calculate maximum redeemable shares while maintaining a pro-rata distribution
        redeemableShares_ =
            partialLiquidity_ ? lockedShares_ * availableLiquidity_ / totalRequestedLiquidity_ : lockedShares_;

        resultingAssets_ = redeemableShares_ * totalAssetsWithLosses_ / totalSupply_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _poolConfigurator() internal view returns (address poolConfigurator_) {
        poolConfigurator_ = ADDRESSES_PROVIDER.getPoolConfigurator();
    }

    function _poolAdmin() internal view returns (address poolAdmin_) {
        poolAdmin_ = IPoolConfigurator(_poolConfigurator()).admin();
    }

    function _globals() internal view returns (address globals_) {
        globals_ = ADDRESSES_PROVIDER.getLopoGlobals();
    }

    function _asset() internal view returns (address asset_) {
        asset_ = IPoolConfigurator(_poolConfigurator()).asset();
    }

    function _pool() internal view returns (address pool_) {
        pool_ = IPoolConfigurator(_poolConfigurator()).pool();
    }

    function _emitUpdate(address account_, uint256 lockedShares_, uint256 exitCycleId_) internal {
        if (lockedShares_ == 0) {
            emit WithdrawalCancelled(account_);
            return;
        }

        (uint256 windowStart_, uint256 windowEnd_) = getWindowAtId(exitCycleId_);

        emit WithdrawalUpdated(account_, lockedShares_, windowStart_.toUint64(), windowEnd_.toUint64());
    }

    function _emitProcess(address account_, uint256 sharesToRedeem_, uint256 assetsToWithdraw_) internal {
        if (sharesToRedeem_ == 0) {
            return;
        }

        emit WithdrawalProcessed(account_, sharesToRedeem_, assetsToWithdraw_);
    }

    function _revertIfNotPoolAdmin() internal view {
        address poolAdmin_ = _poolAdmin();
        if (msg.sender != poolAdmin_) {
            revert Errors.NotPoolAdmin(msg.sender);
        }
    }

    function _revertIfNotPoolConfigurator() internal view {
        address poolConfigurator_ = _poolConfigurator();
        if (msg.sender != poolConfigurator_) {
            revert Errors.NotPoolConfigurator(msg.sender);
        }
    }
}
