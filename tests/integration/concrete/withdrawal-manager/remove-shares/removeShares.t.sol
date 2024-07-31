// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { WithdrawalManager_Integration_Shared_Test } from "../../../shared/withdrawal-manager/WithdrawalManager.t.sol";

contract removeShares_Integration_Concrete_Test is WithdrawalManager_Integration_Shared_Test {
    modifier notOverRemove() {
        _;
    }

    function setUp() public virtual override(WithdrawalManager_Integration_Shared_Test) {
        WithdrawalManager_Integration_Shared_Test.setUp();

        addDefaultShares();
    }

    function test_RevertWhen_NotPoolConfigurator() external {
        changePrank(users.caller);
        vm.expectRevert(abi.encodeWithSelector(Errors.NotPoolConfigurator.selector, users.caller));

        removeDefaultShares();
    }

    function test_RevertWhen_WithdrawalPending() external whenCallerPoolConfigurator {
        vm.expectRevert(abi.encodeWithSelector(Errors.WithdrawalManager_WithdrawalPending.selector, users.receiver));
        removeDefaultShares();
    }

    function test_RevertWhen_Overremove() external whenCallerPoolConfigurator notWithdrawalPending {
        uint256 lockedShares_ = defaults.ADD_SHARES();
        uint256 removeShares_ = lockedShares_ + 1;

        vm.warp(defaults.WINDOW_3());
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.WithdrawalManager_Overremove.selector, users.receiver, removeShares_, lockedShares_
            )
        );
        withdrawalManager.removeShares({ shares_: removeShares_, owner_: users.receiver });
    }

    function test_removeShares() public whenCallerPoolConfigurator notWithdrawalPending notOverRemove {
        uint256 addShares_ = defaults.ADD_SHARES();
        uint256 removeShares_ = defaults.REMOVE_SHARES();

        uint256 expectedWindowStart_ = defaults.WINDOW_3() + 2 * defaults.CYCLE_DURATION();
        uint256 expectedWindowEnd_ = expectedWindowStart_ + defaults.WINDOW_DURATION();

        vm.warp(defaults.WINDOW_3());

        expectCallToTransfer({ asset: pool, to: users.receiver, amount: removeShares_ });
        vm.expectEmit(address(withdrawalManager));
        emit WithdrawalUpdated({
            account_: users.receiver,
            lockedShares_: addShares_ - removeShares_,
            windowStart_: uint64(expectedWindowStart_),
            windowEnd_: uint64(expectedWindowEnd_)
        });

        uint256 sharesReturned_ = removeDefaultShares();

        assertEq(sharesReturned_, removeShares_);
    }
}
