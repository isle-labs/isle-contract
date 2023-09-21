// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolConfigurator_Integration_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract previewRedeem_Integration_Concrete_Test is PoolConfigurator_Integration_Shared_Test {
    function setUp() public virtual override(PoolConfigurator_Integration_Shared_Test) {
        PoolConfigurator_Integration_Shared_Test.setUp();
    }

    function test_previewRedeem() external {
        changePrank({ msgSender: address(pool) });
        requestDefaultRedeem();

        vm.warp({ timestamp: defaults.WINDOW_3() });

        uint256 actualResultingAssets_ =
            poolConfigurator.previewRedeem({ owner_: users.receiver, shares_: defaults.REDEEM_SHARES() });
        uint256 expectedResultingAssets_ = defaults.REDEEM_SHARES() * defaults.POOL_ASSETS() / defaults.POOL_SHARES();

        assertEq(actualResultingAssets_, expectedResultingAssets_);
    }
}
