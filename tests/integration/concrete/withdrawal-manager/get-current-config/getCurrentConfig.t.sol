// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { WithdrawalManager } from "contracts/libraries/types/DataTypes.sol";

import { WithdrawalManager_Integration_Shared_Test } from "../../../shared/withdrawal-manager/WithdrawalManager.t.sol";

contract getCurrentConfig_Integration_Concrete_Test is WithdrawalManager_Integration_Shared_Test {
    function setUp() public virtual override(WithdrawalManager_Integration_Shared_Test) {
        WithdrawalManager_Integration_Shared_Test.setUp();
    }

    function test_getCurrentConfig() public {
        WithdrawalManager.CycleConfig memory actualConfig_ = withdrawalManager.getCurrentConfig();
        WithdrawalManager.CycleConfig memory expectedConfig_ = WithdrawalManager.CycleConfig({
            initialCycleId: 1,
            initialCycleTime: uint64(MAY_1_2023),
            cycleDuration: defaults.CYCLE_DURATION(),
            windowDuration: defaults.WINDOW_DURATION()
        });

        assertEq(actualConfig_, expectedConfig_);
    }
}
