// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { IsleGlobals_Integration_Concrete_Test } from "../IsleGlobals.t.sol";
import { Callable_Integration_Shared_Test } from "tests/integration/shared/isle-globals/callable.t.sol";

contract SetMaxCoverLiquidation_Integration_Concrete_Test is
    IsleGlobals_Integration_Concrete_Test,
    Callable_Integration_Shared_Test
{
    function setUp() public virtual override(IsleGlobals_Integration_Concrete_Test, Callable_Integration_Shared_Test) {
        IsleGlobals_Integration_Concrete_Test.setUp();
    }

    function test_RevertWhen_CallerNotGovernor() external {
        changePrank(users.eve);
        uint24 maxCoverLiquidation = defaults.MAX_COVER_LIQUIDATION();
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.governor, users.eve));
        isleGlobals.setMaxCoverLiquidation(address(poolConfigurator), maxCoverLiquidation);
    }

    function test_SetMaxCoverLiquidation() external whenCallerGovernor {
        vm.expectEmit(true, true, true, true);
        emit MaxCoverLiquidationSet(address(poolConfigurator), defaults.MAX_COVER_LIQUIDATION());
        isleGlobals.setMaxCoverLiquidation(address(poolConfigurator), defaults.MAX_COVER_LIQUIDATION());

        assertEq(isleGlobals.maxCoverLiquidation(address(poolConfigurator)), defaults.MAX_COVER_LIQUIDATION());
    }
}
