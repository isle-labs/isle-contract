// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { UUPSProxy } from "../contracts/libraries/upgradability/UUPSProxy.sol";

import { IsleGlobals } from "../contracts/IsleGlobals.sol";
import { Receivable } from "../contracts/Receivable.sol";
import { PoolAddressesProvider } from "../contracts/PoolAddressesProvider.sol";
import { PoolConfigurator } from "../contracts/PoolConfigurator.sol";
import { LoanManager } from "../contracts/LoanManager.sol";
import { WithdrawalManager } from "../contracts/WithdrawalManager.sol";

import { BaseScript } from "./Base.s.sol";

/// @notice Deploys a pool
/// @notice usage: forge script --broadcast --verify scripts/DeployPool.s.sol
contract DeployPool is BaseScript {
    function run(
        address asset_,
        address globals_,
        address receivable_
    )
        public
        virtual
        returns (
            PoolAddressesProvider poolAddressesProvider_,
            address poolConfigurator_,
            address loanManager_,
            address withdrawalManager_
        )
    {
        poolAddressesProvider_ = deployPoolAddressesProvider(IsleGlobals(globals_));

        initGlobals({ globals_: IsleGlobals(globals_), asset_: asset_, receivable_: receivable_ });

        poolConfigurator_ = deployPoolConfigurator(poolAddressesProvider_, asset_);
        loanManager_ = deployLoanManager(poolAddressesProvider_, asset_);
        withdrawalManager_ = deployWithdrawalManager(poolAddressesProvider_);
    }

    function deployPoolAddressesProvider(IsleGlobals globals_)
        internal
        broadcast(governor)
        returns (PoolAddressesProvider poolAddressesProvider_)
    {
        poolAddressesProvider_ = new PoolAddressesProvider("ChargeSmith", globals_);
    }

    function initGlobals(IsleGlobals globals_, address asset_, address receivable_) internal broadcast(governor) {
        globals_.setValidPoolAdmin(poolAdmin, true);
        globals_.setValidPoolAsset(asset_, true);
        globals_.setValidReceivableAsset(receivable_, true);
    }

    function deployPoolConfigurator(
        PoolAddressesProvider poolAddressesProvider_,
        address asset_
    )
        internal
        broadcast(governor)
        returns (address poolConfigurator_)
    {
        address poolConfiguratorImpl_ = address(new PoolConfigurator(poolAddressesProvider_));

        bytes memory params_ = abi.encodeWithSelector(
            PoolConfigurator.initialize.selector,
            address(poolAddressesProvider_),
            poolAdmin,
            asset_,
            "ChargeSmith Pool",
            "CHG"
        );
        poolAddressesProvider_.setPoolConfiguratorImpl(address(poolConfiguratorImpl_), params_);
        poolConfigurator_ = poolAddressesProvider_.getPoolConfigurator();
    }

    function deployLoanManager(
        PoolAddressesProvider poolAddressesProvider_,
        address asset_
    )
        internal
        broadcast(governor)
        returns (address loanManager_)
    {
        address loanManagerImpl_ = address(new LoanManager(poolAddressesProvider_));

        bytes memory params_ = abi.encodeWithSelector(LoanManager.initialize.selector, asset_);

        poolAddressesProvider_.setLoanManagerImpl(address(loanManagerImpl_), params_);
        loanManager_ = poolAddressesProvider_.getLoanManager();
    }

    function deployWithdrawalManager(PoolAddressesProvider poolAddressesProvider_)
        internal
        broadcast(governor)
        returns (address withdrawalManager_)
    {
        address withdrawalManagerImpl_ = address(new WithdrawalManager(poolAddressesProvider_));
        bytes memory params_ = abi.encodeWithSelector(
            WithdrawalManager.initialize.selector,
            address(poolAddressesProvider_),
            7 days, // cycle duration
            3 days // window duration
        );
        poolAddressesProvider_.setWithdrawalManagerImpl(withdrawalManagerImpl_, params_);
        withdrawalManager_ = poolAddressesProvider_.getWithdrawalManager();
    }
}
