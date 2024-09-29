// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolConfigurator_Integration_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract HasSufficientCover_Integration_Concrete_Test is PoolConfigurator_Integration_Shared_Test {
    function setUp() public virtual override(PoolConfigurator_Integration_Shared_Test) {
        PoolConfigurator_Integration_Shared_Test.setUp();

        changePrank(users.governor);
        poolConfigurator.setMinCover(defaults.MIN_COVER_AMOUNT());

        changePrank(users.poolAdmin);
    }

    function test_HasSufficientCover() external {
        poolConfigurator.depositCover(defaults.COVER_AMOUNT());
        assertTrue(poolConfigurator.hasSufficientCover());
    }
}
