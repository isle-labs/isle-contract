// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Integration_Test } from "../../Integration.t.sol";

abstract contract Pool_Integration_Shared_Test is Integration_Test {
    function setUp() public virtual override(Integration_Test) {
        Integration_Test.setUp();

        configurePoolConfigurator();
        configurePool(); // initialized pool state for testing
    }
}
