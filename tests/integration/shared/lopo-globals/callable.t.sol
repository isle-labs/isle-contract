// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { LopoGlobals_Integration_Shared_Test } from "./LopoGlobals.t.sol";

abstract contract Callable_Integration_Shared_Test is LopoGlobals_Integration_Shared_Test {
    function setUp() public virtual override { }

    modifier whenCallerGovernor() {
        changePrank(users.governor);
        _;
    }
}
