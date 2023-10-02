// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { LopoGlobals_Integration_Concrete_Test } from "../LopoGlobals.t.sol";
import { Callable_Integration_Shared_Test } from "tests/integration/shared/lopo-globals/callable.t.sol";

contract SetLopoVault_Integration_Concrete_Test is
    LopoGlobals_Integration_Concrete_Test,
    Callable_Integration_Shared_Test
{
    function setUp() public virtual override(LopoGlobals_Integration_Concrete_Test, Callable_Integration_Shared_Test) {
        LopoGlobals_Integration_Concrete_Test.setUp();
    }

    modifier WhenVaultIsNotZeroAddress() {
        _;
    }

    function test_RevertWhen_CallerNotGovernor() external {
        changePrank(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.Globals_CallerNotGovernor.selector, users.governor, users.eve));
        lopoGlobals.setLopoVault(address(0));
    }

    function test_RevertWhen_VaultIsZeroAddress() external WhenCallerGovernor {
        changePrank(users.governor);
        vm.expectRevert(abi.encodeWithSelector(Errors.Globals_InvalidVault.selector, address(0)));
        lopoGlobals.setLopoVault(address(0));
    }

    function test_SetLopoVault() external WhenCallerGovernor WhenVaultIsNotZeroAddress {
        changePrank(users.governor);
        address previousVault = lopoGlobals.lopoVault();

        vm.expectEmit(true, true, true, true);
        emit LopoVaultSet(previousVault, users.governor);

        lopoGlobals.setLopoVault(users.governor);
        assertEq(lopoGlobals.lopoVault(), users.governor);
    }
}
