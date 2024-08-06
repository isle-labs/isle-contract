// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { WithdrawalManager_Integration_Shared_Test } from "../../../shared/withdrawal-manager/WithdrawalManager.t.sol";

contract AddShares_Integration_Concrete_Test is WithdrawalManager_Integration_Shared_Test {
    uint256 private _currentCycleId = 1;
    uint256 private _expectedExitCycleId = 3;

    modifier whenLockedSharesNotZero() {
        _;
    }

    function setUp() public virtual override(WithdrawalManager_Integration_Shared_Test) {
        WithdrawalManager_Integration_Shared_Test.setUp();

        changePrank(address(poolConfigurator));
    }

    function test_RevertWhen_CallerNotPoolConfigurator() external {
        changePrank(users.caller);
        vm.expectRevert(abi.encodeWithSelector(Errors.NotPoolConfigurator.selector, users.caller));
        addDefaultShares();
    }

    function test_RevertWhen_WithdrawalPending() external whenCallerPoolConfigurator {
        addDefaultShares();

        vm.expectRevert(abi.encodeWithSelector(Errors.WithdrawalManager_WithdrawalPending.selector, users.receiver));
        addDefaultShares();
    }

    function test_RevertWhen_LockedSharesIsZero() external whenCallerPoolConfigurator whenWithdrawalNotPending {
        vm.expectRevert(abi.encodeWithSelector(Errors.WithdrawalManager_NoOp.selector, users.receiver));
        withdrawalManager.addShares({ shares_: 0, owner_: users.receiver });
    }

    function test_AddShares() public whenCallerPoolConfigurator whenWithdrawalNotPending whenLockedSharesNotZero {
        uint256 addShares_ = defaults.ADD_SHARES();
        (uint64 windowStart_, uint64 windowEnd_) = withdrawalManager.getWindowAtId(_expectedExitCycleId);

        expectCallToTransferFrom({
            asset: pool,
            from: address(poolConfigurator),
            to: address(withdrawalManager),
            amount: addShares_
        });
        vm.expectEmit(address(withdrawalManager));
        emit WithdrawalUpdated({
            account_: users.receiver,
            lockedShares_: addShares_,
            windowStart_: windowStart_,
            windowEnd_: windowEnd_
        });

        addDefaultShares();

        assertEq(withdrawalManager.exitCycleId(users.receiver), _expectedExitCycleId);
        assertEq(withdrawalManager.lockedShares(users.receiver), addShares_);
    }
}
