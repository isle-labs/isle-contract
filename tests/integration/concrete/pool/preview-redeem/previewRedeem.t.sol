// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { Pool_Integration_Shared_Test } from "../../../shared/pool/Pool.t.sol";

contract PreviewRedeem_Pool_Integration_Concrete_Test is Pool_Integration_Shared_Test {
    function setUp() public virtual override(Pool_Integration_Shared_Test) {
        Pool_Integration_Shared_Test.setUp();
    }

    function test_PreviewRedeem() external {
        requestDefaultRedeem();
        vm.warp({ timestamp: defaults.WINDOW_3() });
        uint256 actualAssets_ = pool.previewRedeem({ shares: defaults.REDEEM_SHARES() });
        uint256 expectedAssets_ = defaults.REDEEM_SHARES() * defaults.POOL_ASSETS() / defaults.POOL_SHARES();
        assertEq(actualAssets_, expectedAssets_);
    }
}
