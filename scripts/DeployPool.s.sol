// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { IIsleGlobals } from "../contracts/interfaces/IIsleGlobals.sol";

import { PoolAddressesProvider } from "../contracts/PoolAddressesProvider.sol";
import { PoolConfigurator } from "../contracts/PoolConfigurator.sol";
import { LoanManager } from "../contracts/LoanManager.sol";
import { WithdrawalManager } from "../contracts/WithdrawalManager.sol";

import { BaseScript } from "./Base.s.sol";

contract DeployPool is BaseScript {
    function run(
        address globals_,
        address asset_
    )
        public
        virtual
        returns (PoolAddressesProvider poolAddressesProvider_)
    {
        poolAddressesProvider_ = deployPoolAddressesProvider();
        initGlobals(poolAddressesProvider_, globals_, asset_);
        deployPoolConfigurator(poolAddressesProvider_, asset_);
        deployLoanManager(poolAddressesProvider_);
        deployWithdrawalManager(poolAddressesProvider_);
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
        address globals_,
        address asset_
    )
        internal
        broadcast(governor)
    {
        // Set {IsleGlobals}
        poolAddressesProvider_.setIsleGlobals(globals_);

        // Configure Globals so that {PoolConfigurator} can be properly deployed
        IIsleGlobals(globals_).setValidPoolAdmin(poolAdmin, true);
        IIsleGlobals(globals_).setValidPoolAsset(asset_, true);
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
