// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { IsleGlobals_Unit_Concrete_Test } from "../IsleGlobals.t.sol";

contract IsFunctionPaused_IsleGlobals_Unit_Concrete_Test is IsleGlobals_Unit_Concrete_Test {
    function setUp() public virtual override(IsleGlobals_Unit_Concrete_Test) {
        IsleGlobals_Unit_Concrete_Test.setUp();
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

    function test_IsFunctionPaused() external whenFunctionNotUnpaused whenContractNotPaused whenProtocolNotPaused {
        assertEq(isleGlobals.isFunctionPaused(defaults.PAUSED_CONTRACT(), defaults.PAUSED_FUNCTION_SIG()), false);
    }
}
