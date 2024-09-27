// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Base_Test } from "../../../Base.t.sol";

abstract contract IsleGlobals_Unit_Concrete_Test is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();

        changePrank(users.governor);
        isleGlobals = deployGlobals();
    }

    modifier whenCallerGovernor() {
        changePrank(users.governor);
        _;
    }

    modifier whenContractNotPaused() {
        changePrank(users.governor);
        isleGlobals.setContractPaused(defaults.PAUSED_CONTRACT(), false);
        _;
    }

    modifier whenFunctionNotUnpaused() {
        changePrank(users.governor);
        isleGlobals.setFunctionUnpaused(defaults.PAUSED_CONTRACT(), defaults.PAUSED_FUNCTION_SIG(), false);
        _;
    }

    modifier whenProtocolNotPaused() {
        changePrank(users.governor);
        isleGlobals.setProtocolPaused(false);
        _;
    }
}
