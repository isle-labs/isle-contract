// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolConfigurator_Integration_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract TotalAssets_Integration_Concrete_Test is PoolConfigurator_Integration_Shared_Test {
    uint256 _expectedTotalAssets;

    function setUp() public virtual override(PoolConfigurator_Integration_Shared_Test) {
        PoolConfigurator_Integration_Shared_Test.setUp();

        _expectedTotalAssets = defaults.POOL_ASSETS();
    }

    function test_TotalAssets() external {
        assertEq(poolConfigurator.totalAssets(), _expectedTotalAssets);
    }
}
