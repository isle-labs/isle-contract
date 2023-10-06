// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { IsleGlobals_Integration_Concrete_Test } from "../IsleGlobals.t.sol";
import { Callable_Integration_Shared_Test } from "tests/integration/shared/isle-globals/callable.t.sol";

contract SetMinCover_Integration_Concrete_Test is
    IsleGlobals_Integration_Concrete_Test,
    Callable_Integration_Shared_Test
{
    function setUp() public virtual override(IsleGlobals_Integration_Concrete_Test, Callable_Integration_Shared_Test) {
        IsleGlobals_Integration_Concrete_Test.setUp();
    }

    function test_RevertWhen_CallerNotGovernor() external {
        changePrank(users.eve);
        uint104 minCover = defaults.MIN_COVER_AMOUNT();
        vm.expectRevert(abi.encodeWithSelector(Errors.Globals_CallerNotGovernor.selector, users.governor, users.eve));
        isleGlobals.setMinCover(address(poolConfigurator), minCover);
    }

    function test_SetMinCover() external whenCallerGovernor {
        vm.expectEmit(true, true, true, true);
        emit MinCoverSet(address(poolConfigurator), defaults.MIN_COVER_AMOUNT());
        isleGlobals.setMinCover(address(poolConfigurator), defaults.MIN_COVER_AMOUNT());

        assertEq(isleGlobals.minCover(address(poolConfigurator)), defaults.MIN_COVER_AMOUNT());
    }
}
