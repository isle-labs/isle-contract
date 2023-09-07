// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolConfigurator_Integration_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract MaxRedeem_Integration_Concrete_Test is PoolConfigurator_Integration_Shared_Test {
    uint256 private _expectedMaxRedeem;

    function setUp() public virtual override(PoolConfigurator_Integration_Shared_Test) {
        PoolConfigurator_Integration_Shared_Test.setUp();

        _expectedMaxRedeem = defaults.REDEEM_AMOUNT();

        changePrank(users.receiver);
        pool.requestRedeem({ shares_: defaults.REDEEM_AMOUNT(), owner_: users.receiver });
    }

    function test_maxRedeem() external {
        vm.warp({ timestamp: defaults.WINDOW_3() });
        assertEq(poolConfigurator.maxRedeem({ owner_: users.receiver }), _expectedMaxRedeem);
    }
}
