// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { PoolConfigurator } from "contracts/PoolConfigurator.sol";
import { IPoolAddressesProvider } from "contracts/interfaces/IPoolAddressesProvider.sol";
import { IPoolConfigurator } from "contracts/interfaces/IPoolConfigurator.sol";

import { PoolConfigurator_Integration_Shared_Test, Integration_Test } from "./PoolConfigurator.t.sol";

abstract contract Initialize_Integration_Shared_Test is PoolConfigurator_Integration_Shared_Test {
    IPoolConfigurator public poolConfiguratorNotInitialized;

    IPoolAddressesProvider internal poolAddressesProviderNew;
    IPoolConfigurator internal poolConfiguratorNotInitializedNew;

    function setUp() public virtual override {
        Integration_Test.setUp();

        changePrank(users.governor);
        lopoGlobals = deployGlobals();
        poolConfiguratorNotInitialized = deployPoolSideWithPoolConfiguratorNotInitialized();
        poolConfiguratorNotInitializedNew = deployPoolSideWithPoolConfiguratorNotInitializedNew();

        setDefaultGlobals(poolAddressesProvider);
    }

    function deployPoolSideWithPoolConfiguratorNotInitialized()
        internal
        returns (IPoolConfigurator poolConfigurator_)
    {
        poolAddressesProvider = deployPoolAddressesProvider();

        address poolConfiguratorImpl_ = address(new PoolConfigurator(poolAddressesProvider));
        poolAddressesProvider.setPoolConfiguratorImpl(poolConfiguratorImpl_, bytes(""));
        poolConfigurator_ = IPoolConfigurator(poolAddressesProvider.getPoolConfigurator());
    }

    function deployPoolSideWithPoolConfiguratorNotInitializedNew()
        internal
        returns (IPoolConfigurator poolConfigurator_)
    {
        poolAddressesProviderNew = deployPoolAddressesProvider();
        poolAddressesProviderNew.setLopoGlobals(address(lopoGlobals));

        address poolConfiguratorImpl_ = address(new PoolConfigurator(poolAddressesProviderNew));
        poolAddressesProviderNew.setPoolConfiguratorImpl(poolConfiguratorImpl_, bytes(""));
        poolConfigurator_ = IPoolConfigurator(poolAddressesProviderNew.getPoolConfigurator());
    }
}
