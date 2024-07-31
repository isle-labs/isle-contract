// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { WithdrawalManager_Integration_Shared_Test } from "../../../shared/withdrawal-manager/WithdrawalManager.t.sol";

contract previewRedeem_Integration_Concrete_Test is WithdrawalManager_Integration_Shared_Test {
    function setUp() public virtual override(WithdrawalManager_Integration_Shared_Test) {
        WithdrawalManager_Integration_Shared_Test.setUp();
        addDefaultShares();
    }

    function test_RedeemSharesNotEqualToLockedShares() external {
        uint256 redeemShares_ = defaults.ADD_SHARES() + 1;

        (uint256 actualRedeemableShares_, uint256 actualResultingAssets_) =
            withdrawalManager.previewRedeem({ owner_: users.receiver, shares_: redeemShares_ });

        assertEq(actualRedeemableShares_, 0);
        assertEq(actualResultingAssets_, 0);
    }

    function test_RedeemSharesIsZero() external {
        (uint256 actualRedeemableShares_, uint256 actualResultingAssets_) =
            withdrawalManager.previewRedeem({ owner_: users.receiver, shares_: 0 });

        assertEq(actualRedeemableShares_, 0);
        assertEq(actualResultingAssets_, 0);
    }

    function test_NotInTheWindow() external validRequestShares {
        uint256 addShares_ = defaults.ADD_SHARES();

        (uint256 actualRedeemableShares_, uint256 actualResultingAssets_) =
            withdrawalManager.previewRedeem({ owner_: users.receiver, shares_: addShares_ });

        assertEq(actualRedeemableShares_, 0);
        assertEq(actualResultingAssets_, 0);
    }

    function test_previewRedeem() public validRequestShares inTheWindow {
        uint256 addShares_ = defaults.ADD_SHARES();

        vm.warp(defaults.WINDOW_3());

        (uint256 actualRedeemableShares_, uint256 actualResultingAssets_) =
            withdrawalManager.previewRedeem({ owner_: users.receiver, shares_: addShares_ });

        uint256 expectedRedeemableShares_ = addShares_;
        uint256 expectedResultingAssets_ = addShares_ * defaults.POOL_ASSETS() / defaults.POOL_SHARES();

        assertEq(actualRedeemableShares_, expectedRedeemableShares_);
        assertEq(actualResultingAssets_, expectedResultingAssets_);
    }
}
