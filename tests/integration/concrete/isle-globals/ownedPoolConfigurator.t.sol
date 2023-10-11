// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IsleGlobals_Integration_Concrete_Test } from "./IsleGlobals.t.sol";

contract OwnedPoolConfigurator_Integration_Concrete_Test is IsleGlobals_Integration_Concrete_Test {
    function setUp() public virtual override(IsleGlobals_Integration_Concrete_Test) {
        IsleGlobals_Integration_Concrete_Test.setUp();
    }

    function test_OwnedPoolConfigurator() external {
        assertEq(isleGlobals.ownedPoolConfigurator(users.poolAdmin), address(poolConfigurator));
        assertEq(isleGlobals.ownedPoolConfigurator(users.caller), address(0));
    }
}
