// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { WithdrawalManager } from "contracts/libraries/types/DataTypes.sol";

import { WithdrawalManager_Integration_Shared_Test } from "../../../shared/withdrawal-manager/WithdrawalManager.t.sol";

contract GetCurrentCycleId_Integration_Concrete_Test is WithdrawalManager_Integration_Shared_Test {
    function setUp() public virtual override(WithdrawalManager_Integration_Shared_Test) {
        WithdrawalManager_Integration_Shared_Test.setUp();
    }

    function test_GetCurrentCycleId() public {
        uint256 expectedCurrentCycleId_ = 1;
        uint256 actualCurrentCycleId_ = withdrawalManager.getCurrentCycleId();

        assertEq(actualCurrentCycleId_, expectedCurrentCycleId_);
    }
}
