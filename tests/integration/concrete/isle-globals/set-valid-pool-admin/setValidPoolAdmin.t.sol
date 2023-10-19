// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { IsleGlobals_Integration_Concrete_Test } from "../IsleGlobals.t.sol";
import { Callable_Integration_Shared_Test } from "tests/integration/shared/isle-globals/callable.t.sol";

contract SetValidPoolAdmin_Integration_Concrete_Test is
    IsleGlobals_Integration_Concrete_Test,
    Callable_Integration_Shared_Test
{
    function setUp() public virtual override(IsleGlobals_Integration_Concrete_Test, Callable_Integration_Shared_Test) {
        IsleGlobals_Integration_Concrete_Test.setUp();
    }

    function test_RevertWhen_CallerNotGovernor() external {
        changePrank(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotGovernor.selector, users.governor, users.eve));
        isleGlobals.setValidPoolAdmin(address(users.poolAdmin), false);
    }

    function test_SetValidPoolAdmin() external whenCallerGovernor {
        assertEq(isleGlobals.isPoolAdmin(address(users.poolAdmin)), true);

        vm.expectEmit(true, true, true, true);
        emit ValidPoolAdminSet(address(users.poolAdmin), false);
        isleGlobals.setValidPoolAdmin(address(users.poolAdmin), false);

        assertEq(isleGlobals.isPoolAdmin(address(users.poolAdmin)), false);
    }
}
