// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Pool_Integration_Shared_Test } from "../../../shared/pool/Pool.t.sol";

contract MaxMint_Integration_Concrete_Test is Pool_Integration_Shared_Test {
    uint256 private _expectedMaxMint;

    function setUp() public virtual override(Pool_Integration_Shared_Test) {
        Pool_Integration_Shared_Test.setUp();

        _expectedMaxMint = pool.previewDeposit(defaults.POOL_LIMIT() - defaults.POOL_ASSETS());
    }

    function test_maxMint() external {
        assertEq(pool.maxMint(users.notWhitelistedReceiver), _expectedMaxMint);
        assertEq(pool.maxMint(users.receiver), _expectedMaxMint);

        changePrank(users.poolAdmin);
        poolConfigurator.setOpenToPublic(false);

        assertEq(pool.maxMint(users.notWhitelistedReceiver), 0);
        assertEq(pool.maxMint(users.receiver), _expectedMaxMint);
    }
}
