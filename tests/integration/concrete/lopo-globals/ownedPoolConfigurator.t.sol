// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { LopoGlobals_Integration_Concrete_Test } from "./lopoGlobals.t.sol";

contract OwnedPoolConfigurator_Integration_Concrete_Test is LopoGlobals_Integration_Concrete_Test {
    function setUp() public virtual override(LopoGlobals_Integration_Concrete_Test) {
        LopoGlobals_Integration_Concrete_Test.setUp();
    }

    function test_OwnedPoolConfigurator() external {
        assertEq(lopoGlobals.ownedPoolConfigurator(users.poolAdmin), address(poolConfigurator));
        assertEq(lopoGlobals.ownedPoolConfigurator(users.caller), address(0));
    }
}
