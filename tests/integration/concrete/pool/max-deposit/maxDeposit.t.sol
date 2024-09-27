// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Pool_Integration_Shared_Test } from "../../../shared/pool/Pool.t.sol";

contract MaxDeposit_Pool_Integration_Concrete_Test is Pool_Integration_Shared_Test {
    uint256 private _expectedMaxDeposit;

    function setUp() public virtual override(Pool_Integration_Shared_Test) {
        Pool_Integration_Shared_Test.setUp();

        _expectedMaxDeposit = defaults.POOL_LIMIT() - defaults.POOL_ASSETS();
    }

    function test_MaxDeposit() external {
        assertEq(pool.maxDeposit(users.notWhitelistedReceiver), _expectedMaxDeposit);
        assertEq(pool.maxDeposit(users.receiver), _expectedMaxDeposit);

        changePrank(users.poolAdmin);
        poolConfigurator.setOpenToPublic(false);

        assertEq(pool.maxDeposit(users.notWhitelistedReceiver), 0);
        assertEq(pool.maxDeposit(users.receiver), _expectedMaxDeposit);
    }
}
