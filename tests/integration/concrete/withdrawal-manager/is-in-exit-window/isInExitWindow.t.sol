// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { WithdrawalManager_Integration_Shared_Test } from "../../../shared/withdrawal-manager/WithdrawalManager.t.sol";

contract isInExitWindow_Integration_Concrete_Test is WithdrawalManager_Integration_Shared_Test {
    function setUp() public virtual override(WithdrawalManager_Integration_Shared_Test) {
        WithdrawalManager_Integration_Shared_Test.setUp();
    }

    function test_NoExitCycleId() external {
        assertFalse(withdrawalManager.isInExitWindow(users.receiver));
    }

    function test_isInExitWindow() public {
        uint256 addShares_ = defaults.ADD_SHARES();
        withdrawalManager.addShares({ shares_: addShares_, owner_: users.receiver });

        vm.warp(defaults.WINDOW_3());
        assertTrue(withdrawalManager.isInExitWindow(users.receiver));
    }
}
