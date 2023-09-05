// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { LopoGlobals_Integration_Shared_Test } from "./lopoGlobals.t.sol";

abstract contract Paused_Integration_Shared_Test is LopoGlobals_Integration_Shared_Test {
    function setUp() public virtual override { }

    modifier whenContractNotPaused() {
        changePrank(users.governor);
        lopoGlobals.setContractPause(defaults.PAUSED_CONTRACT(), false);
        _;
    }

    modifier whenFunctionNotUnpaused() {
        changePrank(users.governor);
        lopoGlobals.setFunctionUnpause(defaults.PAUSED_CONTRACT(), defaults.PAUSED_FUNCTION_SIG(), false);
        _;
    }
}
