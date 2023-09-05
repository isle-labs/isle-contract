// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Pool_Integration_Shared_Test } from "../../../shared/pool/Pool.t.sol";

contract BalanceOfAssets_Integration_Concrete_Test is Pool_Integration_Shared_Test {
    function setUp() public virtual override(Pool_Integration_Shared_Test) {
        Pool_Integration_Shared_Test.setUp();
    }

    function test_balanceOfAssets() external {
        uint256 expectedBalance_ = defaults.POOL_ASSETS();
        assertAlmostEq(pool.balanceOfAssets(users.receiver), expectedBalance_, defaults.DELTA());
    }
}
