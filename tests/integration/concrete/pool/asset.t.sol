// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Pool_Integration_Concrete_Test } from "./Pool.t.sol";

contract Asset_Integration_Concrete_Test is Pool_Integration_Concrete_Test {
    function setUp() public virtual override(Pool_Integration_Concrete_Test) {
        Pool_Integration_Concrete_Test.setUp();
    }

    function test_Asset() external {
        assertEq(pool.asset(), address(usdc));
    }
}
