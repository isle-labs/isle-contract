// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Pool_Integration_Shared_Test } from "../../../shared/pool/Pool.t.sol";

contract Asset_Pool_Integration_Concrete_Test is Pool_Integration_Shared_Test {
    function setUp() public virtual override(Pool_Integration_Shared_Test) {
        Pool_Integration_Shared_Test.setUp();
    }

    function test_Decimals() external {
        assertEq(pool.decimals(), defaults.DECIMALS_OFFSET() + defaults.UNDERLYING_DECIMALS());
    }
}
