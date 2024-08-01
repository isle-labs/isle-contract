// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { Errors } from "contracts/libraries/Errors.sol";

import { WithdrawalManager_Integration_Shared_Test } from "../../../shared/withdrawal-manager/WithdrawalManager.t.sol";

contract ProcessExit_Integration_Concrete_Test is WithdrawalManager_Integration_Shared_Test {
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

    function test_processExit_PartialLiquidity()
        public
        whenCallerPoolConfigurator
        hasRequest
        validRequestShares
        inTheWindow
    {
        uint256 principal_ = defaults.PRINCIPAL_REQUESTED();
        _createPartialLiquidityPool(principal_);

        // process exit
        changePrank({ msgSender: address(poolConfigurator) });
        (uint256 actualRedeemableShares_,) =
            withdrawalManager.processExit({ requestedShares_: principal_, owner_: users.receiver });

        assertEq(withdrawalManager.exitCycleId(users.receiver), withdrawalManager.getCurrentCycleId() + 1);
        assertEq(withdrawalManager.lockedShares(users.receiver), principal_ - actualRedeemableShares_);
    }

    function _createPartialLiquidityPool(uint256 principal_) private {
        uint256 drainAmount_ = defaults.POOL_SHARES() - defaults.ADD_SHARES() - principal_;

        // down size the pool
        changePrank(users.receiver);
        pool.requestRedeem(drainAmount_, users.receiver);
        vm.warp(defaults.WINDOW_3());
        pool.redeem(drainAmount_, users.receiver, users.receiver);

        // deposit cover
        changePrank(users.poolAdmin);
        poolConfigurator.depositCover(defaults.COVER_AMOUNT());

        // create loan
        createDefaultLoan();

        // seller withdraw fund
        changePrank(users.seller);
        IERC721(address(receivable)).approve(address(loanManager), defaults.RECEIVABLE_TOKEN_ID());
        loanManager.withdrawFunds(1, address(users.seller), principal_);

        // receiver request redeem
        changePrank(users.receiver);
        pool.requestRedeem(principal_, users.receiver);

        // move to the next redeemable window
        vm.warp(defaults.WINDOW_5());
    }
}
