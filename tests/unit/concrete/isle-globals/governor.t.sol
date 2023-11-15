// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IsleGlobals_Unit_Concrete_Test } from "./IsleGlobals.t.sol";

contract Governor_IsleGlobals_Unit_Concrete_Test is IsleGlobals_Unit_Concrete_Test {
    function setUp() public virtual override(IsleGlobals_Unit_Concrete_Test) {
        IsleGlobals_Unit_Concrete_Test.setUp();
    }

    function test_Governor() external {
        assertEq(isleGlobals.governor(), users.governor);
    }
}
