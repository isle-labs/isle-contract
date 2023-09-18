// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Integration_Test } from "../../Integration.t.sol";

abstract contract PoolConfigurator_Integration_Shared_Test is Integration_Test {
    function setUp() public virtual override(Integration_Test) {
        Integration_Test.setUp();

        configurePoolConfigurator();
        configurePool();
        configureGlobals();

        changePrank(users.poolAdmin);
    }

    function configureGlobals() internal {
        changePrank(users.governor);
        lopoGlobals.setMinCover(address(poolConfigurator), defaults.MIN_COVER_AMOUNT());
    }

    modifier whenCallerPoolAdmin() {
        // Make the Admin the caller in the rest of this test suite.
        changePrank({ msgSender: users.poolAdmin });
        _;
    }
}
