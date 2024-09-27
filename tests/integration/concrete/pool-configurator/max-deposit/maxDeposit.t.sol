// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolConfigurator_Integration_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract MaxDeposit_Integration_Concrete_Test is PoolConfigurator_Integration_Shared_Test {
    uint256 private _expectedMaxDeposit;

    function setUp() public virtual override(PoolConfigurator_Integration_Shared_Test) {
        PoolConfigurator_Integration_Shared_Test.setUp();
        _expectedMaxDeposit = defaults.POOL_LIMIT() - defaults.POOL_ASSETS();
    }

    function test_MaxDeposit() external {
        assertEq(poolConfigurator.maxDeposit(users.caller), _expectedMaxDeposit);
    }
}
