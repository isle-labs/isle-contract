// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { WithdrawalManager_Integration_Shared_Test } from "../../../shared/withdrawal-manager/WithdrawalManager.t.sol";

contract addShares_Integration_Concrete_Test is WithdrawalManager_Integration_Shared_Test {
    uint256 private _currentCycleId = 1;
    uint256 private _expectedExitCycleId = 3;

    function setUp() public virtual override(WithdrawalManager_Integration_Shared_Test) {
        WithdrawalManager_Integration_Shared_Test.setUp();

        changePrank(address(poolConfigurator));
    }

    function test_addShares() public whenCallerPoolConfigurator {
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
