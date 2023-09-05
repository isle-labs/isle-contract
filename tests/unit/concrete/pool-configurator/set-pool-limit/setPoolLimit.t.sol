// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolConfigurator_Unit_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract setPoolLimit_Unit_Concrete_Test is PoolConfigurator_Unit_Shared_Test {
    uint256 private _poolLimit;

    function setUp() public virtual override(PoolConfigurator_Unit_Shared_Test) {
        PoolConfigurator_Unit_Shared_Test.setUp();
        _poolLimit = defaults.POOL_LIMIT();
    }

    function test_RevertWhen_CallerNotPoolAdmin() external {
        // Make eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.poolAdmin, users.eve));
        poolConfigurator.setPoolLimit(_poolLimit);
    }

    function test_setPoolLimit() external whenCallerPoolAdmin {
        vm.expectEmit({ emitter: address(poolConfigurator) });
        emit PoolLimitSet({ poolLimit_: _poolLimit });

        poolConfigurator.setPoolLimit(_poolLimit);
        assertEq(poolConfigurator.poolLimit(), _poolLimit);
    }
}
