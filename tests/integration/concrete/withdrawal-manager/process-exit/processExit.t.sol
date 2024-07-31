// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { WithdrawalManager_Integration_Shared_Test } from "../../../shared/withdrawal-manager/WithdrawalManager.t.sol";

contract processExit_Integration_Concrete_Test is WithdrawalManager_Integration_Shared_Test {
    modifier hasRequest() {
        _;
    }

    function setUp() public virtual override(WithdrawalManager_Integration_Shared_Test) {
        WithdrawalManager_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_NotPoolConfigurator() external {
        changePrank(users.receiver);
        vm.expectRevert(abi.encodeWithSelector(Errors.NotPoolConfigurator.selector, users.receiver));
        withdrawalManager.processExit({ requestedShares_: 0, owner_: users.receiver });
    }

    function test_RevertWhen_NoRequest() external whenCallerPoolConfigurator {
        vm.expectRevert(abi.encodeWithSelector(Errors.WithdrawalManager_NoRequest.selector, users.receiver));
        withdrawalManager.processExit({ requestedShares_: 0, owner_: users.receiver });
    }

    function test_RevertWhen_InvalidShares() external whenCallerPoolConfigurator hasRequest {
        addDefaultShares();

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.WithdrawalManager_InvalidShares.selector, users.receiver, 0, defaults.ADD_SHARES()
            )
        );
        withdrawalManager.processExit({ requestedShares_: 0, owner_: users.receiver });
    }

    function test_RevertWhen_NotInWindow() external whenCallerPoolConfigurator hasRequest validRequestShares {
        uint256 addShares_ = defaults.ADD_SHARES();
        uint64 startWindow = defaults.WINDOW_3();
        uint64 endWindow = defaults.WINDOW_3() + defaults.WINDOW_DURATION();

        addDefaultShares();

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.WithdrawalManager_NotInWindow.selector, block.timestamp, startWindow, endWindow
            )
        );
        withdrawalManager.processExit({ requestedShares_: addShares_, owner_: users.receiver });
    }

    function test_processExit() public whenCallerPoolConfigurator hasRequest validRequestShares inTheWindow {
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

        assertEq(withdrawalManager.exitCycleId(users.receiver), 0);
        assertEq(withdrawalManager.lockedShares(users.receiver), 0);

        assertEq(actualRedeemableShares_, expectedRedeemableShares_);
        assertEq(actualResultingAssets_, expectedResultingAssets_);
    }
}
