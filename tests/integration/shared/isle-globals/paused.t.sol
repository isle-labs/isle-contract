// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IsleGlobals_Integration_Shared_Test } from "./isleGlobals.t.sol";

abstract contract Paused_Integration_Shared_Test is IsleGlobals_Integration_Shared_Test {
    function setUp() public virtual override { }

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
}
