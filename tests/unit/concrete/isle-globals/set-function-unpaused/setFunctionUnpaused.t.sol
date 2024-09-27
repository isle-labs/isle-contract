// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { IsleGlobals_Unit_Concrete_Test } from "../IsleGlobals.t.sol";

contract SetFunctionUnpaused_IsleGlobals_Unit_Concrete_Test is IsleGlobals_Unit_Concrete_Test {
    function setUp() public virtual override(IsleGlobals_Unit_Concrete_Test) {
        IsleGlobals_Unit_Concrete_Test.setUp();
    }

    function test_RevertWhen_CallerNotGovernor() external {
        changePrank(users.eve);
        address pausedContract = defaults.PAUSED_CONTRACT();
        bytes4 pausedFunctionSig = defaults.PAUSED_FUNCTION_SIG();
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotGovernor.selector, users.governor, users.eve));
        isleGlobals.setFunctionUnpaused(pausedContract, pausedFunctionSig, true);
    }

    function test_SetFunctionUnpaused() external whenCallerGovernor {
        vm.expectEmit(true, true, true, true);
        emit FunctionUnpausedSet(users.governor, defaults.PAUSED_CONTRACT(), defaults.PAUSED_FUNCTION_SIG(), true);
        isleGlobals.setFunctionUnpaused(defaults.PAUSED_CONTRACT(), defaults.PAUSED_FUNCTION_SIG(), true);
    }
}
