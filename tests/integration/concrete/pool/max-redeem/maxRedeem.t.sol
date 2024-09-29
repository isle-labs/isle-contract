// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { Errors } from "contracts/libraries/Errors.sol";

import { Pool_Integration_Shared_Test } from "../../../shared/pool/Pool.t.sol";

contract MaxRedeem_Pool_Integration_Concrete_Test is Pool_Integration_Shared_Test {
    function setUp() public virtual override(Pool_Integration_Shared_Test) {
        Pool_Integration_Shared_Test.setUp();
    }

    function test_MaxRedeem() external {
        requestDefaultRedeem();

        vm.warp({ timestamp: defaults.WINDOW_3() });

        uint256 expectedMaxRedeem_ = defaults.REDEEM_SHARES();

        assertEq(pool.maxRedeem({ owner: users.receiver }), expectedMaxRedeem_);
    }
}
