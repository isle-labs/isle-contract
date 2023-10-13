// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { UUPSProxy } from "../contracts/libraries/upgradability/UUPSProxy.sol";

import { IsleGlobals } from "../contracts/IsleGlobals.sol";
import { Receivable } from "../contracts/Receivable.sol";
import { PoolAddressesProvider } from "../contracts/PoolAddressesProvider.sol";
import { PoolConfigurator } from "../contracts/PoolConfigurator.sol";
import { LoanManager } from "../contracts/LoanManager.sol";
import { WithdrawalManager } from "../contracts/WithdrawalManager.sol";

import { BaseScript } from "./Base.s.sol";

/// @notice Deploys the core contracts of Isle Finance
contract DeployCore is BaseScript {
    function run(address asset_)
        public
        virtual
        returns (IsleGlobals globals_, Receivable receivable_, PoolAddressesProvider poolAddressesProvider_)
    {
        receivable_ = deployReceivable();
        globals_ = deployGlobals();
        poolAddressesProvider_ = deployPoolAddressesProvider();

        initGlobals({
            poolAddressesProvider_: poolAddressesProvider_,
            globals_: globals_,
            asset_: asset_,
            receivable_: address(receivable_)
        });

        deployPoolConfigurator(poolAddressesProvider_, asset_);
        deployLoanManager(poolAddressesProvider_);
        deployWithdrawalManager(poolAddressesProvider_);
    }

    function deployReceivable() internal broadcast(deployer) returns (Receivable receivable_) {
        receivable_ = Receivable(address(new UUPSProxy(address(new Receivable()), "")));
        receivable_.initialize(governor);
    }

    function deployGlobals() internal broadcast(deployer) returns (IsleGlobals globals_) {
        globals_ = new IsleGlobals();
        globals_.initialize(governor);
    }

    function deployPoolAddressesProvider()
        internal
        broadcast(deployer)
        returns (PoolAddressesProvider poolAddressesProvider_)
    {
        poolAddressesProvider_ = new PoolAddressesProvider("ChargeSmith", governor);
    }

    function initGlobals(
        PoolAddressesProvider poolAddressesProvider_,
        IsleGlobals globals_,
        address asset_,
        address receivable_
    )
        internal
        broadcast(governor)
    {
        poolAddressesProvider_.setIsleGlobals(address(globals_));

        globals_.setValidPoolAdmin(poolAdmin, true);
        globals_.setValidPoolAsset(asset_, true);
        globals_.setValidCollateralAsset(receivable_, true);
        globals_.setValidCollateralAsset(address(receivable_), true);
        globals_.setProtocolFee(0.1e6);
    }

    function deployPoolConfigurator(
        PoolAddressesProvider poolAddressesProvider_,
        address asset_
    )
        internal
        broadcast(governor)
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
    }

    function deployLoanManager(PoolAddressesProvider poolAddressesProvider_) internal broadcast(governor) {
        address loanManagerImpl_ = address(new LoanManager(poolAddressesProvider_));
        poolAddressesProvider_.setLoanManagerImpl(address(loanManagerImpl_));
    }

    function deployWithdrawalManager(PoolAddressesProvider poolAddressesProvider_) internal broadcast(governor) {
        address withdrawalManagerImpl_ = address(new WithdrawalManager(poolAddressesProvider_));
        bytes memory params_ = abi.encodeWithSelector(
            WithdrawalManager.initialize.selector,
            address(poolAddressesProvider_),
            7 days, // cycle duration
            3 days // window duration
        );
        poolAddressesProvider_.setWithdrawalManagerImpl(withdrawalManagerImpl_, params_);
    }
}
