// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { WithdrawalManager } from "contracts/libraries/types/DataTypes.sol";

import { WithdrawalManager_Integration_Shared_Test } from "../../../shared/withdrawal-manager/WithdrawalManager.t.sol";

contract GetConfigAtId_Integration_Concrete_Test is WithdrawalManager_Integration_Shared_Test {
    uint256 private _initCycleId = 1;

    function setUp() public virtual override(WithdrawalManager_Integration_Shared_Test) {
        WithdrawalManager_Integration_Shared_Test.setUp();
    }

    function test_getConfigAtId() public {
        WithdrawalManager.CycleConfig memory actualConfig_ = withdrawalManager.getConfigAtId(_initCycleId);
        WithdrawalManager.CycleConfig memory expectedConfig_ = WithdrawalManager.CycleConfig({
            initialCycleId: 1,
            initialCycleTime: uint64(MAY_1_2023),
            cycleDuration: defaults.CYCLE_DURATION(),
            windowDuration: defaults.WINDOW_DURATION()
        });

        assertEq(actualConfig_, expectedConfig_);
    }

    function test_AgetConfigAtId_HasNewConfigs() public {
        uint256 newCycleId_ = 5;

        setNewExitConfig();

        WithdrawalManager.CycleConfig memory actualInitConfig_ = withdrawalManager.getConfigAtId(_initCycleId);
        WithdrawalManager.CycleConfig memory expectedInitConfig_ = WithdrawalManager.CycleConfig({
            initialCycleId: 1,
            initialCycleTime: uint64(MAY_1_2023),
            cycleDuration: defaults.CYCLE_DURATION(),
            windowDuration: defaults.WINDOW_DURATION()
        });

        assertEq(actualInitConfig_, expectedInitConfig_);

        WithdrawalManager.CycleConfig memory actualNewConfig_ = withdrawalManager.getConfigAtId(newCycleId_);
        WithdrawalManager.CycleConfig memory expectedNewConfig_ = WithdrawalManager.CycleConfig({
            initialCycleId: 4,
            initialCycleTime: defaults.WINDOW_4(),
            cycleDuration: defaults.NEW_CYCLE_DURATION(),
            windowDuration: defaults.NEW_WINDOW_DURATION()
        });

        assertEq(actualNewConfig_, expectedNewConfig_);
    }
}
