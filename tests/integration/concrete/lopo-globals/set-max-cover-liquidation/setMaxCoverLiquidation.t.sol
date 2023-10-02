// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { LopoGlobals_Integration_Concrete_Test } from "../LopoGlobals.t.sol";
import { Callable_Integration_Shared_Test } from "tests/integration/shared/lopo-globals/callable.t.sol";

contract SetMaxCoverLiquidation_Integration_Concrete_Test is
    LopoGlobals_Integration_Concrete_Test,
    Callable_Integration_Shared_Test
{
    function setUp() public virtual override(LopoGlobals_Integration_Concrete_Test, Callable_Integration_Shared_Test) {
        LopoGlobals_Integration_Concrete_Test.setUp();
    }

    function test_RevertWhen_CallerNotGovernor() external {
        changePrank(users.eve);
        uint24 maxCoverLiquidation = defaults.MAX_COVER_LIQUIDATION();
        vm.expectRevert(abi.encodeWithSelector(Errors.Globals_CallerNotGovernor.selector, users.governor, users.eve));
        lopoGlobals.setMaxCoverLiquidation(address(poolConfigurator), maxCoverLiquidation);
    }

    function test_SetMaxCoverLiquidation() external WhenCallerGovernor {
        changePrank(users.governor);
        vm.expectEmit(true, true, true, true);
        emit MaxCoverLiquidationSet(address(poolConfigurator), defaults.MAX_COVER_LIQUIDATION());
        lopoGlobals.setMaxCoverLiquidation(address(poolConfigurator), defaults.MAX_COVER_LIQUIDATION());

        assertEq(lopoGlobals.maxCoverLiquidation(address(poolConfigurator)), defaults.MAX_COVER_LIQUIDATION());
    }
}
