// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { Errors } from "contracts/libraries/Errors.sol";

import { IsleGlobals_Unit_Concrete_Test } from "../IsleGlobals.t.sol";

contract SetValidPoolAdmin_IsleGlobals_Unit_Concrete_Test is IsleGlobals_Unit_Concrete_Test {
    function setUp() public virtual override(IsleGlobals_Unit_Concrete_Test) {
        IsleGlobals_Unit_Concrete_Test.setUp();
    }

    function test_RevertWhen_CallerNotGovernor() external {
        changePrank(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotGovernor.selector, users.governor, users.eve));
        isleGlobals.setValidPoolAdmin(address(users.eve), true);
    }

    function test_SetValidPoolAdmin() external whenCallerGovernor {
        vm.expectEmit(true, true, true, true);
        emit ValidPoolAdminSet(address(users.poolAdmin), true);
        isleGlobals.setValidPoolAdmin(address(users.poolAdmin), true);

        assertEq(isleGlobals.isPoolAdmin(address(users.poolAdmin)), true);
    }
}
