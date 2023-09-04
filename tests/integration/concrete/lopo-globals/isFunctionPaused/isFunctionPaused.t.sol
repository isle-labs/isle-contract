// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { LopoGlobals_Integration_Concrete_Test } from "../lopoGlobals.t.sol";
import { Paused_Integration_Shared_Test } from "../../../shared/lopo-globals/paused.t.sol";

contract IsFunctionPaused_Integration_Concrete_Test is
    LopoGlobals_Integration_Concrete_Test,
    Paused_Integration_Shared_Test
{
    function setUp() public virtual override(LopoGlobals_Integration_Concrete_Test, Paused_Integration_Shared_Test) {
        LopoGlobals_Integration_Concrete_Test.setUp();
    }

    function test_FunctionUnpaused() external {
        lopoGlobals.setFunctionUnpause(defaults.PAUSED_CONTRACT(), defaults.PAUSED_FUNCTION_SIG(), true);
        assertEq(lopoGlobals.isFunctionPaused(defaults.PAUSED_CONTRACT(), defaults.PAUSED_FUNCTION_SIG()), false);
    }

    function test_ContractPaused() external whenFunctionNotUnpaused {
        lopoGlobals.setContractPause(defaults.PAUSED_CONTRACT(), true);
        assertEq(lopoGlobals.isFunctionPaused(defaults.PAUSED_CONTRACT(), defaults.PAUSED_FUNCTION_SIG()), true);
    }

    function test_ProtocolPaused() external whenFunctionNotUnpaused whenContractNotPaused {
        lopoGlobals.setProtocolPause(true);
        assertEq(lopoGlobals.isFunctionPaused(defaults.PAUSED_CONTRACT(), defaults.PAUSED_FUNCTION_SIG()), true);
    }

    function test_ProtocolUnpaused() external whenFunctionNotUnpaused whenContractNotPaused {
        assertEq(lopoGlobals.isFunctionPaused(defaults.PAUSED_CONTRACT(), defaults.PAUSED_FUNCTION_SIG()), false);
    }
}
