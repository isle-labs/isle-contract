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

<<<<<<< HEAD:tests/integration/concrete/lopo-globals/is-function-paused/isFunctionPaused.t.sol
    function test_IsFunctionPaused_FunctionUnpaused() external {
        lopoGlobals.setFunctionUnpause(defaults.PAUSED_CONTRACT(), defaults.PAUSED_FUNCTION_SIG(), true);
=======
    function test_IsFunctionPaused_WhenFunctionUnpaused() external {
        lopoGlobals.setFunctionUnpaused(defaults.PAUSED_CONTRACT(), defaults.PAUSED_FUNCTION_SIG(), true);
>>>>>>> main:tests/integration/concrete/lopo-globals/isFunctionPaused/isFunctionPaused.t.sol
        assertEq(lopoGlobals.isFunctionPaused(defaults.PAUSED_CONTRACT(), defaults.PAUSED_FUNCTION_SIG()), false);
    }

    function test_IsFunctionPaused_ContractPaused() external whenFunctionNotUnpaused {
        lopoGlobals.setContractPause(defaults.PAUSED_CONTRACT(), true);
        assertEq(lopoGlobals.isFunctionPaused(defaults.PAUSED_CONTRACT(), defaults.PAUSED_FUNCTION_SIG()), true);
    }

<<<<<<< HEAD:tests/integration/concrete/lopo-globals/is-function-paused/isFunctionPaused.t.sol
    function test_IsFunctionPaused_ProtocolPaused() external whenFunctionNotUnpaused whenContractNotPaused {
        lopoGlobals.setProtocolPause(true);
=======
    function test_IsFunctionPaused_WhenProtocolPaused() external whenFunctionNotUnpaused whenContractNotPaused {
        lopoGlobals.setProtocolPaused(true);
>>>>>>> main:tests/integration/concrete/lopo-globals/isFunctionPaused/isFunctionPaused.t.sol
        assertEq(lopoGlobals.isFunctionPaused(defaults.PAUSED_CONTRACT(), defaults.PAUSED_FUNCTION_SIG()), true);
    }

    function test_IsFunctionPaused_ProtocolUnpaused() external whenFunctionNotUnpaused whenContractNotPaused {
        assertEq(lopoGlobals.isFunctionPaused(defaults.PAUSED_CONTRACT(), defaults.PAUSED_FUNCTION_SIG()), false);
    }
}
