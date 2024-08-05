// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { WithdrawalManager } from "contracts/libraries/types/DataTypes.sol";

import { WithdrawalManager_Integration_Shared_Test } from "../../../shared/withdrawal-manager/WithdrawalManager.t.sol";

contract getConfigAtId_Integration_Concrete_Test is WithdrawalManager_Integration_Shared_Test {
    uint256 private _cycleId1 = 1;

    function setUp() public virtual override(WithdrawalManager_Integration_Shared_Test) {
        WithdrawalManager_Integration_Shared_Test.setUp();
    }

    function test_getConfigAtId() public {
        WithdrawalManager.CycleConfig memory actualConfig_ = withdrawalManager.getConfigAtId(_cycleId1);
        WithdrawalManager.CycleConfig memory expectedConfig_ = WithdrawalManager.CycleConfig({
            initialCycleId: 1,
            initialCycleTime: uint64(MAY_1_2023),
            cycleDuration: defaults.CYCLE_DURATION(),
            windowDuration: defaults.WINDOW_DURATION()
        });

        assertEq(actualConfig_, expectedConfig_);
    }

    function test_AgetConfigAtId_MultupleConfigs() public {
        uint256 cycleId10_ = 10;
        uint64 newCycleDuration_ = defaults.NEW_CYCLE_DURATION();
        uint64 newWindowDuration_ = defaults.NEW_WINDOW_DURATION();

        changePrank(users.poolAdmin);
        withdrawalManager.setExitConfig(newCycleDuration_, newWindowDuration_);

        WithdrawalManager.CycleConfig memory actualInitConfig_ = withdrawalManager.getConfigAtId(_cycleId1);
        WithdrawalManager.CycleConfig memory expectedInitConfig_ = WithdrawalManager.CycleConfig({
            initialCycleId: 1,
            initialCycleTime: uint64(MAY_1_2023),
            cycleDuration: defaults.CYCLE_DURATION(),
            windowDuration: defaults.WINDOW_DURATION()
        });

        assertEq(actualInitConfig_, expectedInitConfig_);

        WithdrawalManager.CycleConfig memory actualNewConfig_ = withdrawalManager.getConfigAtId(cycleId10_);
        WithdrawalManager.CycleConfig memory expectedNewConfig_ = WithdrawalManager.CycleConfig({
            initialCycleId: 4,
            initialCycleTime: defaults.WINDOW_4(),
            cycleDuration: newCycleDuration_,
            windowDuration: newWindowDuration_
        });

        assertEq(actualNewConfig_, expectedNewConfig_);
    }
}
