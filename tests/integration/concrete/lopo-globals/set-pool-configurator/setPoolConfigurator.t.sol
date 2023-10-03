// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { LopoGlobals_Integration_Concrete_Test } from "../LopoGlobals.t.sol";
import { Callable_Integration_Shared_Test } from "tests/integration/shared/lopo-globals/callable.t.sol";

contract SetPoolConfigurator_Integration_Concrete_Test is
    LopoGlobals_Integration_Concrete_Test,
    Callable_Integration_Shared_Test
{
    function setUp() public virtual override(LopoGlobals_Integration_Concrete_Test, Callable_Integration_Shared_Test) {
        LopoGlobals_Integration_Concrete_Test.setUp();
    }

    modifier WhenPoolAdminIsValid() {
        _;
    }

    modifier WhenPoolAdminDoNotOwnPoolConfigurator() {
        _;
    }

    modifier WhenPoolConfiguratorIsNotZeroAddress() {
        _;
    }

    function test_RevertWhen_CallerNotGovernor() external {
        changePrank(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.Globals_CallerNotGovernor.selector, users.governor, users.eve));
        lopoGlobals.setPoolConfigurator(users.poolAdmin, address(poolConfigurator));
    }

    function test_RevertWhen_PoolAdminNotValid() external WhenCallerGovernor {
        vm.expectRevert(abi.encodeWithSelector(Errors.Globals_ToInvalidPoolAdmin.selector, users.eve));
        lopoGlobals.setPoolConfigurator(users.eve, address(poolConfigurator));
    }

    function test_RevertWhen_PoolAdminAlreadyOwnPoolConfigurator() external WhenCallerGovernor WhenPoolAdminIsValid {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Globals_AlreadyHasConfigurator.selector, users.poolAdmin, address(poolConfigurator)
            )
        );
        lopoGlobals.setPoolConfigurator(users.poolAdmin, address(poolConfigurator));
    }

    function test_RevertWhen_PoolConfiguratorIsZeroAddress()
        external
        WhenCallerGovernor
        WhenPoolAdminIsValid
        WhenPoolAdminDoNotOwnPoolConfigurator
    {
        // onboard users.caller as pool admin
        lopoGlobals.setValidPoolAdmin(users.caller, true);

        vm.expectRevert(abi.encodeWithSelector(Errors.Globals_ToInvalidPoolConfigurator.selector, address(0)));
        lopoGlobals.setPoolConfigurator(users.caller, address(0));
    }

    function test_SetPoolConfigurator()
        external
        WhenCallerGovernor
        WhenPoolAdminIsValid
        WhenPoolAdminDoNotOwnPoolConfigurator
        WhenPoolConfiguratorIsNotZeroAddress
    {
        // onboard users.caller as pool admin
        lopoGlobals.setValidPoolAdmin(users.caller, true);

        vm.expectEmit(true, true, true, true);
        emit PoolConfiguratorSet(users.caller, address(poolConfigurator));
        lopoGlobals.setPoolConfigurator(users.caller, address(poolConfigurator));

        assertEq(lopoGlobals.ownedPoolConfigurator(users.caller), address(poolConfigurator));
    }
}
