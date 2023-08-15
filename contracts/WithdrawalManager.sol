// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { VersionedInitializable } from "./libraries/upgradability/VersionedInitializable.sol";
import { Errors } from "./libraries/Errors.sol";

import { IWithdrawalManager } from "./interfaces/IWithdrawalManager.sol";
import { IPoolConfigurator } from "./interfaces/IPoolConfigurator.sol";
import { IPoolAddressesProvider } from "./interfaces/IPoolAddressesProvider.sol";
import { ILopoGlobals } from "./interfaces/ILopoGlobals.sol";

import { WithdrawalManagerStorage } from "./WithdrawalManagerStorage.sol";

contract WithdrawalManager is WithdrawalManagerStorage, VersionedInitializable {
    using SafeCast for uint64;

    /*//////////////////////////////////////////////////////////////////////////
                                PUBLIC CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/


    uint256 public constant WITHDRAWAL_MANAGER_REVISION = 0x1;

    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    /*//////////////////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier onlyPoolAdmin() {
        _revertIfNotPoolAdmin();
        _;
    }

    modifier whenProtocolNotPaused() {
        if(ILopoGlobals(_globals()).protocolPaused()) {
            revert Errors.ProtocolPaused();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IPoolAddressesProvider provider) {
        ADDRESSES_PROVIDER = provider;
    }

    function initialize(IPoolAddressesProvider provider_) external initializer {
        if (ADDRESSES_PROVIDER != provider_) {
            revert Errors.InvalidAddressProvider({
                expectedProvider: address(ADDRESSES_PROVIDER),
                provider: address(provider_)
            });
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                            CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function getRevision() internal pure virtual override returns (uint256 revision_) {
        revision_ = WITHDRAWAL_MANAGER_REVISION;
    }

    function getConfigAtId(uint256 cycleId_) public view override returns (CycleConfig memory config_) {
        uint256 configId_ = latestConfigId;

        if (configId_ == 0)
            return cycleConfigs[configId_];

        while (cycleId_ < cycleConfigs[configId_].initialCycleId) {
            --configId_;
        }

        config_ = cycleConfigs[configId_];
    }

    function getCurrentConfig() public view override returns (CycleConfig memory config_) {
        uint256 configId_ = latestConfigId;

        while (block.timestamp < cycleConfigs[configId_].initialCycleTime) {
            --configId_;
        }

        config_ = cycleConfigs[configId_];
    }

    function getCurrentCycleId() public view override returns (uint256 cycleId_) {
        CycleConfig memory config_ = getCurrentConfig();
        cycleId_ = config_.initialCycleId + ((block.timestamp - config_.initialCycleTime) / config_.cycleDuration);
    }

    function getWindowStart(uint256 cycleId_) public view override returns (uint256 windowStart_) {
        CycleConfig memory config_ = getConfigAtId(cycleId_);

        windowStart_ = config_.initialCycleTime + ((cycleId_ - config_.initialCycleId) * config_.cycleDuration);
    }

    function lockedLiquidity() external view override returns (uint256 lockedLiquidity_) { }

    function isInExitWindow(address owner_) external view override returns (bool isInExitWindow_) { }

    function previewRedeem(
        address owner_,
        uint256 shares_
    )
        external
        view
        override
        returns (uint256 redeemableShares_, uint256 resultingAssets_)
    { }

    function previewWithdraw(
        address owner_,
        uint256 assets_
    )
        external
        view
        override
        returns (uint256 redeemableAssets_, uint256 resultingShares_)
    { }

    /*//////////////////////////////////////////////////////////////////////////
                            ADMINISTRATIVE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function initConfig(uint256 cycleDuration_, uint256 windowDuration_) external override onlyPoolAdmin whenProtocolNotPaused{

        if (windowDuration_ == 0) {
            revert Errors.WithdrawalManager_ZeroWindow();
        }

        if (windowDuration_ > cycleDuration_) {
            revert Errors.WithdrawalManager_WindowGreaterThanCycle();
        }

        cycleConfigs[0] = CycleConfig({
            initialCycleId: 1,
            initialCycleTime: uint64(block.timestamp),
            cycleDuration: uint64(cycleDuration_),
            windowDuration: uint64(windowDuration_)
        });

        emit Initialized(address(ADDRESSES_PROVIDER), cycleDuration_, windowDuration_);
        emit ConfigurationUpdated({
            configId_: 0,
            initialCycleId_: 1,
            initialCycleTime_: uint64(block.timestamp),
            cycleDuration_: uint64(cycleDuration_),
            windowDuration_: uint64(windowDuration_)
        });
    }

    function setExitConfig(uint256 cycleDuration_, uint256 windowDuration_) external override whenProtocolNotPaused {

        if (windowDuration_ == 0) {
            revert Errors.WithdrawalManager_ZeroWindow();
        }

        if (windowDuration_ > cycleDuration_) {
            revert Errors.WithdrawalManager_WindowGreaterThanCycle();
        }

        uint256 currentCycleId_ = getCurrentCycleId();
        uint256 initialCycleId_ = currentCycleId_ + 3;
        uint256 initialCycleTime_ = getWindowStart(currentCycleId_);
        uint256 latestConfigId_ = latestConfigId;

        for (uint256 i = currentCycleId_; i < initialCycleId_; i++) {
            CycleConfig memory config = getConfigAtId(i);

            initialCycleTime_ += config.cycleDuration;
        }

        // if the new config takes effect on the same cycle as the latest config, overwrite it. Otherwise create a new config.
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

    function processExit(
        uint256 requestedShares_,
        address owner_
    )
        external
        override
        returns (uint256 redeemableShares_, uint256 resultingAssets_)
    { }

    function removeShares(uint256 shares_, address owner_) external override returns (uint256 sharesReturned_) { }

    function addShares(uint256 shares_, address owner_) external override { }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _poolConfigurator() internal view returns (address poolConfigurator_) {
        poolConfigurator_ = ADDRESSES_PROVIDER.getPoolConfigurator();
    }

    function _poolAdmin() internal view returns (address poolAdmin_) {
        poolAdmin_ = IPoolConfigurator(_poolConfigurator()).poolAdmin();
    }

    function _globals() internal view returns (address globals_) {
        globals_ = ADDRESSES_PROVIDER.getLopoGlobals();
    }

    function _revertIfNotPoolAdmin() internal view {
        address poolAdmin_ = _poolAdmin();
        if (msg.sender != poolAdmin_) {
            revert Errors.InvalidCaller({ caller: msg.sender, expectedCaller: poolAdmin_ });
        }
    }
}
