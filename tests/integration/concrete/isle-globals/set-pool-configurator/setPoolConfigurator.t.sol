// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { IsleGlobals_Integration_Concrete_Test } from "../IsleGlobals.t.sol";
import { Callable_Integration_Shared_Test } from "tests/integration/shared/isle-globals/callable.t.sol";

contract SetPoolConfigurator_Integration_Concrete_Test is
    IsleGlobals_Integration_Concrete_Test,
    Callable_Integration_Shared_Test
{
    function setUp() public virtual override(IsleGlobals_Integration_Concrete_Test, Callable_Integration_Shared_Test) {
        IsleGlobals_Integration_Concrete_Test.setUp();
    }

    modifier whenPoolAdminIsValid() {
        _;
    }

    modifier whenPoolAdminDoNotOwnPoolConfigurator() {
        _;
    }

    modifier whenPoolConfiguratorIsNotZeroAddress() {
        _;
    }

    function test_RevertWhen_CallerNotGovernor() external {
        changePrank(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.governor, users.eve));
        isleGlobals.setPoolConfigurator(users.poolAdmin, address(poolConfigurator));
    }

    function test_RevertWhen_PoolAdminNotValid() external whenCallerGovernor {
        vm.expectRevert(abi.encodeWithSelector(Errors.Globals_ToInvalidPoolAdmin.selector, users.eve));
        isleGlobals.setPoolConfigurator(users.eve, address(poolConfigurator));
    }

    function test_RevertWhen_PoolAdminAlreadyOwnPoolConfigurator() external whenCallerGovernor whenPoolAdminIsValid {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Globals_AlreadyOwnsConfigurator.selector, users.poolAdmin, address(poolConfigurator)
            )
        );
        isleGlobals.setPoolConfigurator(users.poolAdmin, address(poolConfigurator));
    }

    function test_RevertWhen_PoolConfiguratorIsZeroAddress()
        external
        whenCallerGovernor
        whenPoolAdminIsValid
        whenPoolAdminDoNotOwnPoolConfigurator
    {
        // onboard users.caller as pool admin
        isleGlobals.setValidPoolAdmin(users.caller, true);

        vm.expectRevert(abi.encodeWithSelector(Errors.Globals_ToInvalidPoolConfigurator.selector, address(0)));
        isleGlobals.setPoolConfigurator(users.caller, address(0));
    }

    function test_SetPoolConfigurator()
        external
        whenCallerGovernor
        whenPoolAdminIsValid
        whenPoolAdminDoNotOwnPoolConfigurator
        whenPoolConfiguratorIsNotZeroAddress
    {
        // onboard users.caller as pool admin
        isleGlobals.setValidPoolAdmin(users.caller, true);

        vm.expectEmit(true, true, true, true);
        emit PoolConfiguratorSet(users.caller, address(poolConfigurator));
        isleGlobals.setPoolConfigurator(users.caller, address(poolConfigurator));

        assertEq(isleGlobals.ownedPoolConfigurator(users.caller), address(poolConfigurator));
    }
}
