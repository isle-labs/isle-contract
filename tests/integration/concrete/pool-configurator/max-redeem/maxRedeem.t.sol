// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolConfigurator_Integration_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract MaxRedeem_Integration_Concrete_Test is PoolConfigurator_Integration_Shared_Test {
    function setUp() public virtual override(PoolConfigurator_Integration_Shared_Test) {
        PoolConfigurator_Integration_Shared_Test.setUp();
    }

    function test_MaxRedeem() external {
        requestDefaultRedeem();
        vm.warp({ timestamp: defaults.WINDOW_3() });
        uint256 expectedMaxRedeem_ = defaults.REDEEM_SHARES();
        assertEq(poolConfigurator.maxRedeem({ owner_: users.receiver }), expectedMaxRedeem_);
    }
}
