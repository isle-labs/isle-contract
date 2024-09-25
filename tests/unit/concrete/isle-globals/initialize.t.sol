// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { IIsleGlobals } from "contracts/interfaces/IIsleGlobals.sol";

import { IsleGlobals_Unit_Concrete_Test } from "./IsleGlobals.t.sol";

contract Initialize_IsleGlobals_Unit_Concrete_Test is IsleGlobals_Unit_Concrete_Test {
    function setUp() public virtual override(IsleGlobals_Unit_Concrete_Test) {
        IsleGlobals_Unit_Concrete_Test.setUp();
    }

    function test_initialize() external {
        vm.expectEmit(true, true, true, true);
        emit Initialized(users.governor);
        IIsleGlobals isleGlobals_ = deployGlobals();

        assertEq(isleGlobals_.governor(), users.governor);
    }
}
