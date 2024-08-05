// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { Pool } from "contracts/Pool.sol";

import { Pool_Integration_Shared_Test } from "../../../shared/pool/Pool.t.sol";

contract Redeem_Pool_Integration_Concrete_Test is Pool_Integration_Shared_Test {
    function setUp() public virtual override(Pool_Integration_Shared_Test) {
        Pool_Integration_Shared_Test.setUp();
    }

    modifier whenEnoughLockedShares() {
        _;
    }

    function test_RevertWhen_NotEnoughLockedShares() external {
        uint256 redeemShares_ = defaults.REDEEM_SHARES();
        vm.expectRevert(abi.encodeWithSelector(Errors.Pool_RedeemMoreThanMax.selector, redeemShares_, 0));

        defaultRedeem();
    }

    function test_Redeem() external whenEnoughLockedShares {
        requestDefaultRedeem();

        vm.warp({ timestamp: defaults.WINDOW_3() });

        uint256 expectedAssetsRedeemed_ = defaults.REDEEM_SHARES() * defaults.POOL_ASSETS() / defaults.POOL_SHARES();

        vm.expectEmit(address(pool));
        emit Withdraw({
            sender: users.receiver,
            receiver: users.receiver,
            owner: users.receiver,
            assets: expectedAssetsRedeemed_,
            shares: defaults.REDEEM_SHARES()
        });

        expectCallToTransfer({ to: users.receiver, amount: expectedAssetsRedeemed_ });

        uint256 actualAssetsRedeemed_ = defaultRedeem();

        assertEq(actualAssetsRedeemed_, expectedAssetsRedeemed_, "assets redeemed");
    }

    function test_Redeem_CallerNotOwner() external whenEnoughLockedShares {
        uint256 redeemShares_ = defaults.REDEEM_SHARES();
        uint256 expectedAssetsRedeemed_ = redeemShares_ * defaults.POOL_ASSETS() / defaults.POOL_SHARES();

        requestDefaultRedeem();

        vm.warp({ timestamp: defaults.WINDOW_3() });

        changePrank(users.receiver);
        pool.approve(users.caller, redeemShares_);
        assertEq(pool.allowance(users.receiver, users.caller), redeemShares_);

        changePrank(users.caller);
        uint256 actualAssetsRedeemed_ = pool.redeem({ shares: redeemShares_, receiver: users.receiver, owner: users.receiver });

        assertEq(actualAssetsRedeemed_, expectedAssetsRedeemed_, "assets redeemed");
        assertEq(pool.allowance(users.receiver, users.caller), 0);
    }
}
