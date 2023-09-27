// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolConfigurator_Integration_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract processRedeem_Integration_Concrete_Test is PoolConfigurator_Integration_Shared_Test {
    function setUp() public virtual override(PoolConfigurator_Integration_Shared_Test) {
        PoolConfigurator_Integration_Shared_Test.setUp();
    }

    function test_processRedeem() external whenCallerPool {
        uint256 expectedResultingAssets_ = defaults.REDEEM_SHARES() * defaults.POOL_ASSETS() / defaults.POOL_SHARES();
        uint256 expectedRedeemableShares_ = defaults.REDEEM_SHARES();

        requestDefaultRedeem();

        vm.warp({ timestamp: defaults.WINDOW_3() });

        vm.expectEmit(address(poolConfigurator));
        emit RedeemProcessed({
            owner_: users.receiver,
            redeemableShares_: expectedRedeemableShares_,
            resultingAssets_: expectedResultingAssets_
        });
        (uint256 actualRedeemableShares_, uint256 actualResultingAssets_) = poolConfigurator.processRedeem({
            owner_: users.receiver,
            shares_: defaults.REDEEM_SHARES(),
            sender_: users.receiver
        });

        assertEq(actualResultingAssets_, expectedResultingAssets_);
        assertEq(actualRedeemableShares_, expectedRedeemableShares_);
    }
}
