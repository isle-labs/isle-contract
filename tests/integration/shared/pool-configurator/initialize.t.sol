// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { PoolConfigurator } from "contracts/PoolConfigurator.sol";
import { IPoolAddressesProvider } from "contracts/interfaces/IPoolAddressesProvider.sol";
import { IPoolConfigurator } from "contracts/interfaces/IPoolConfigurator.sol";

import { PoolConfigurator_Integration_Shared_Test, Integration_Test } from "./PoolConfigurator.t.sol";

abstract contract Initialize_Integration_Shared_Test is PoolConfigurator_Integration_Shared_Test {
    IPoolConfigurator public poolConfiguratorNotInitialized;

    function setUp() public virtual override {
        Integration_Test.setUp();

        changePrank(users.governor);
        // deploy a new addresses provider for constructing poolConfiguratorNotInitialized
        poolAddressesProvider = deployPoolAddressesProvider(isleGlobals);
        poolConfiguratorNotInitialized = deployPoolSideWithPoolConfiguratorNotInitialized(poolAddressesProvider);

        setDefaultGlobals(poolAddressesProvider);
    }

    function deployPoolSideWithPoolConfiguratorNotInitialized(IPoolAddressesProvider poolAddressesProvider_)
        internal
        returns (IPoolConfigurator poolConfigurator_)
    {
        address poolConfiguratorImpl_ = address(new PoolConfigurator(poolAddressesProvider_));
        poolAddressesProvider_.setPoolConfiguratorImpl(poolConfiguratorImpl_, bytes(""));
        poolConfigurator_ = IPoolConfigurator(poolAddressesProvider_.getPoolConfigurator());
    }
}
