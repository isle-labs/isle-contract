// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IntegrationTest } from "../../Integration.t.sol";

abstract contract Pool_Integration_Concrete_Test is IntegrationTest {
    function setUp() public virtual override(IntegrationTest) {
        IntegrationTest.setUp();
        // Make the msg sender the default caller
        vm.startPrank(users.caller);
    }
}
