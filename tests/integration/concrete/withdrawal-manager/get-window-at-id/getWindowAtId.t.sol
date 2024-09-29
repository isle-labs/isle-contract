// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { WithdrawalManager } from "contracts/libraries/types/DataTypes.sol";

import { WithdrawalManager_Integration_Shared_Test } from "../../../shared/withdrawal-manager/WithdrawalManager.t.sol";

contract GetWindowAtId_Integration_Concrete_Test is WithdrawalManager_Integration_Shared_Test {
    function setUp() public virtual override(WithdrawalManager_Integration_Shared_Test) {
        WithdrawalManager_Integration_Shared_Test.setUp();
    }

    function test_GetWindowAtId() public {
        uint256 windowId_ = 1;

        uint64 expectedWindowStart_ = defaults.WINDOW_1();
        uint64 expectedWindowEnd_ = defaults.WINDOW_1() + defaults.WINDOW_DURATION();
        (uint64 actualWindowStart_, uint64 actualWindowEnd_) = withdrawalManager.getWindowAtId(windowId_);

        assertEq(actualWindowStart_, expectedWindowStart_);
        assertEq(actualWindowEnd_, expectedWindowEnd_);
    }
}
