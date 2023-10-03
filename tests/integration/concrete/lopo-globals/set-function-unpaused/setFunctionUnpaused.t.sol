// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { LopoGlobals_Integration_Concrete_Test } from "../LopoGlobals.t.sol";
import { Callable_Integration_Shared_Test } from "tests/integration/shared/lopo-globals/callable.t.sol";

contract SetFunctionUnpaused_Integration_Concrete_Test is
    LopoGlobals_Integration_Concrete_Test,
    Callable_Integration_Shared_Test
{
    function setUp() public virtual override(LopoGlobals_Integration_Concrete_Test, Callable_Integration_Shared_Test) {
        LopoGlobals_Integration_Concrete_Test.setUp();
    }

    function test_RevertWhen_CallerNotGovernor() external {
        changePrank(users.eve);
        address pausedContract = defaults.PAUSED_CONTRACT();
        bytes4 pausedFunctionSig = defaults.PAUSED_FUNCTION_SIG();
        vm.expectRevert(abi.encodeWithSelector(Errors.Globals_CallerNotGovernor.selector, users.governor, users.eve));
        lopoGlobals.setFunctionUnpaused(pausedContract, pausedFunctionSig, true);
    }

    function test_SetFunctionUnpaused() external WhenCallerGovernor {
        vm.expectEmit(true, true, true, true);
        emit FunctionUnpausedSet(users.governor, defaults.PAUSED_CONTRACT(), defaults.PAUSED_FUNCTION_SIG(), true);
        lopoGlobals.setFunctionUnpaused(defaults.PAUSED_CONTRACT(), defaults.PAUSED_FUNCTION_SIG(), true);
    }
}
