// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { IsleGlobals_Integration_Concrete_Test } from "../IsleGlobals.t.sol";
import { Callable_Integration_Shared_Test } from "tests/integration/shared/isle-globals/callable.t.sol";

contract SetIsleVault_Integration_Concrete_Test is
    IsleGlobals_Integration_Concrete_Test,
    Callable_Integration_Shared_Test
{
    function setUp() public virtual override(IsleGlobals_Integration_Concrete_Test, Callable_Integration_Shared_Test) {
        IsleGlobals_Integration_Concrete_Test.setUp();
    }

    modifier whenVaultIsNotZeroAddress() {
        _;
    }

    function test_RevertWhen_CallerNotGovernor() external {
        changePrank(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotGovernor.selector, users.governor, users.eve));
        isleGlobals.setIsleVault(address(0));
    }

    function test_RevertWhen_VaultIsZeroAddress() external whenCallerGovernor {
        vm.expectRevert(abi.encodeWithSelector(Errors.Globals_InvalidVault.selector, address(0)));
        isleGlobals.setIsleVault(address(0));
    }

    function test_SetIsleVault() external whenCallerGovernor whenVaultIsNotZeroAddress {
        address previousVault = isleGlobals.isleVault();

        vm.expectEmit(true, true, true, true);
        emit IsleVaultSet(previousVault, users.governor);

        isleGlobals.setIsleVault(users.governor);
        assertEq(isleGlobals.isleVault(), users.governor);
    }
}
