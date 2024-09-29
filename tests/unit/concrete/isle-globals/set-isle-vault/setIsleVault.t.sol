// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { Errors } from "contracts/libraries/Errors.sol";

import { IsleGlobals_Unit_Concrete_Test } from "../IsleGlobals.t.sol";

contract SetIsleVault_IsleGlobals_Unit_Concrete_Test is IsleGlobals_Unit_Concrete_Test {
    function setUp() public virtual override(IsleGlobals_Unit_Concrete_Test) {
        IsleGlobals_Unit_Concrete_Test.setUp();
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
        vm.expectEmit(true, true, true, true);
        emit IsleVaultSet(address(0), users.vault);

        isleGlobals.setIsleVault(users.vault);
        assertEq(isleGlobals.isleVault(), users.vault);
    }

    modifier whenVaultIsNotZeroAddress() {
        _;
    }
}
