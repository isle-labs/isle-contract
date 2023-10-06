// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IsleGlobals_Integration_Concrete_Test } from "../IsleGlobals.t.sol";
import { Paused_Integration_Shared_Test } from "../../../shared/isle-globals/paused.t.sol";

contract IsFunctionPaused_Integration_Concrete_Test is
    IsleGlobals_Integration_Concrete_Test,
    Paused_Integration_Shared_Test
{
    function setUp() public virtual override(IsleGlobals_Integration_Concrete_Test, Paused_Integration_Shared_Test) {
        IsleGlobals_Integration_Concrete_Test.setUp();
    }

    function test_IsFunctionPaused_WhenFunctionUnpaused() external {
        isleGlobals.setFunctionUnpaused(defaults.PAUSED_CONTRACT(), defaults.PAUSED_FUNCTION_SIG(), true);
        assertEq(isleGlobals.isFunctionPaused(defaults.PAUSED_CONTRACT(), defaults.PAUSED_FUNCTION_SIG()), false);
    }

    function test_IsFunctionPaused_WhenContractPaused() external whenFunctionNotUnpaused {
        isleGlobals.setContractPaused(defaults.PAUSED_CONTRACT(), true);
        assertEq(isleGlobals.isFunctionPaused(defaults.PAUSED_CONTRACT(), defaults.PAUSED_FUNCTION_SIG()), true);
    }

    function test_IsFunctionPaused_WhenProtocolPaused() external whenFunctionNotUnpaused whenContractNotPaused {
        isleGlobals.setProtocolPaused(true);
        assertEq(isleGlobals.isFunctionPaused(defaults.PAUSED_CONTRACT(), defaults.PAUSED_FUNCTION_SIG()), true);
    }

    function test_IsFunctionPaused_WhenProtocolUnpaused() external whenFunctionNotUnpaused whenContractNotPaused {
        assertEq(isleGlobals.isFunctionPaused(defaults.PAUSED_CONTRACT(), defaults.PAUSED_FUNCTION_SIG()), false);
    }
}
