// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { WithdrawalManager_Integration_Shared_Test } from "../../../shared/withdrawal-manager/WithdrawalManager.t.sol";

contract processExit_Integration_Concrete_Test is WithdrawalManager_Integration_Shared_Test {
    function setUp() public virtual override(WithdrawalManager_Integration_Shared_Test) {
        WithdrawalManager_Integration_Shared_Test.setUp();
    }

    function test_processExit() public whenCallerPoolConfigurator {
        uint256 addShares_ = defaults.ADD_SHARES();

        uint256 expectedRedeemableShares_ = addShares_;
        uint256 expectedResultingAssets_ = addShares_ * defaults.POOL_ASSETS() / defaults.POOL_SHARES();

        addDefaultShares();

        vm.warp(defaults.WINDOW_3());

        expectCallToTransfer({ asset: pool, to: users.receiver, amount: addShares_ });
        vm.expectEmit(address(withdrawalManager));
        emit WithdrawalProcessed({
            account_: users.receiver,
            sharesToRedeem_: expectedRedeemableShares_,
            assetsToWithdraw_: expectedResultingAssets_
        });
        vm.expectEmit(address(withdrawalManager));
        emit WithdrawalCancelled({ account_: users.receiver });

        (uint256 actualRedeemableShares_, uint256 actualResultingAssets_) =
            withdrawalManager.processExit({ requestedShares_: addShares_, owner_: users.receiver });

        assertEq(actualRedeemableShares_, expectedRedeemableShares_);
        assertEq(actualResultingAssets_, expectedResultingAssets_);
    }
}
