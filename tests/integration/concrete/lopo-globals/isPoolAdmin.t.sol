// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { LopoGlobals_Integration_Concrete_Test } from "./lopoGlobals.t.sol";

contract IsPoolAdmin_Integration_Concrete_Test is LopoGlobals_Integration_Concrete_Test {
    function setUp() public virtual override(LopoGlobals_Integration_Concrete_Test) {
        LopoGlobals_Integration_Concrete_Test.setUp();
    }

    function test_IsPoolAdmin() external {
        assertEq(lopoGlobals.isPoolAdmin(users.poolAdmin), true);
    }

    function test_IsPoolAdmin_WhenCallerNotPoolAdmin() external {
        assertEq(lopoGlobals.isPoolAdmin(users.caller), false);
    }
}
