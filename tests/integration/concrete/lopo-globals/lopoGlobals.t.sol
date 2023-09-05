// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Integration_Test } from "../../Integration.t.sol";

abstract contract LopoGlobals_Integration_Concrete_Test is Integration_Test {
    function setUp() public virtual override(Integration_Test) {
        Integration_Test.setUp();

        // Make the msg sender the default governor
        changePrank(users.governor);
        assignPoolConfigurator();
    }

    function assignPoolConfigurator() internal {
        // assign the pool configurator to specific pool admin
        lopoGlobals.setPoolConfigurator(users.poolAdmin, address(poolConfigurator));
    }
}
