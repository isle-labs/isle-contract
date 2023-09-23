// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { WithdrawalManager } from "contracts/libraries/types/DataTypes.sol";

import { WithdrawalManager_Integration_Shared_Test } from "../../../shared/withdrawal-manager/WithdrawalManager.t.sol";

contract setExitConfig_Integration_Concrete_Test is WithdrawalManager_Integration_Shared_Test {
    function setUp() public virtual override(WithdrawalManager_Integration_Shared_Test) {
        WithdrawalManager_Integration_Shared_Test.setUp();
    }

    function test_setExitConfig() public whenCallerPoolAdmin {
        WithdrawalManager.CycleConfig memory expectedLatestConfig_ = WithdrawalManager.CycleConfig({
            initialCycleId: 4,
            initialCycleTime: defaults.WINDOW_4(),
            windowDuration: defaults.NEW_WINDOW_DURATION(),
            cycleDuration: defaults.NEW_CYCLE_DURATION()
        });

        vm.expectEmit(address(withdrawalManager));
        emit ConfigurationUpdated({
            configId_: withdrawalManager.latestConfigId() + 1,
            initialCycleId_: expectedLatestConfig_.initialCycleId,
            initialCycleTime_: expectedLatestConfig_.initialCycleTime,
            cycleDuration_: expectedLatestConfig_.cycleDuration,
            windowDuration_: expectedLatestConfig_.windowDuration
        });
        setDefaultNewExitConfig();

        WithdrawalManager.CycleConfig memory actualLatestConfig_ =
            withdrawalManager.getCycleConfig(withdrawalManager.latestConfigId());

        assertEq(expectedLatestConfig_, actualLatestConfig_);
    }
}
