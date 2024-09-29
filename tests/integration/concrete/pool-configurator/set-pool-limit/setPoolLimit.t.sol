// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolConfigurator_Integration_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract SetPoolLimit_Integration_Concrete_Test is PoolConfigurator_Integration_Shared_Test {
    function setUp() public virtual override {
        PoolConfigurator_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_CallerNotGovernor() external {
        changePrank(users.eve);
        uint104 poolLimit = defaults.POOL_LIMIT();
        vm.expectRevert(abi.encodeWithSelector(Errors.PoolConfigurator_CallerNotGovernor.selector, users.eve));
        poolConfigurator.setPoolLimit(poolLimit);
    }

    function test_SetPoolLimit() external whenCallerGovernor {
        vm.expectEmit(true, true, true, true);
        emit PoolLimitSet(defaults.POOL_LIMIT());
        poolConfigurator.setPoolLimit(defaults.POOL_LIMIT());
        assertEq(poolConfigurator.poolLimit(), defaults.POOL_LIMIT());
    }
}
