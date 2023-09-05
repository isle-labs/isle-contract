// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { Base_Test } from "../../../Base.t.sol";

import { PoolConfigurator } from "contracts/PoolConfigurator.sol";

abstract contract PoolConfigurator_Unit_Shared_Test is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();

        deployAndLabelContract();

        changePrank(users.poolAdmin);
    }

    function deployAndLabelContract() internal {
        changePrank(users.governor);
        lopoGlobals = deployGlobals();
        poolAddressesProvider = deployPoolAddressesProvider(lopoGlobals);
        changePrank(users.poolAdmin);
        deployPoolConfigurator(poolAddressesProvider);
        poolConfigurator = PoolConfigurator(poolAddressesProvider.getPoolConfigurator());
    }

    modifier whenCallerPoolAdmin() {
        // Make the Admin the caller in the rest of this test suite.
        changePrank({ msgSender: users.poolAdmin });
        _;
    }
}
