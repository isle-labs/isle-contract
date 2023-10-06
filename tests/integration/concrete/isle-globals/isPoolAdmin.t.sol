// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IsleGlobals_Integration_Concrete_Test } from "./IsleGlobals.t.sol";

contract IsPoolAdmin_Integration_Concrete_Test is IsleGlobals_Integration_Concrete_Test {
    function setUp() public virtual override(IsleGlobals_Integration_Concrete_Test) {
        IsleGlobals_Integration_Concrete_Test.setUp();
    }

    function test_IsPoolAdmin() external {
        assertEq(isleGlobals.isPoolAdmin(users.poolAdmin), true);
    }

    function test_IsPoolAdmin_WhenCallerNotPoolAdmin() external {
        assertEq(isleGlobals.isPoolAdmin(users.caller), false);
    }
}
