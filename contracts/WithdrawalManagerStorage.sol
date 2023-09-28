// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { WithdrawalManager } from "./libraries/types/DataTypes.sol";
import { IWithdrawalManagerStorage } from "./interfaces/IWithdrawalManagerStorage.sol";

abstract contract WithdrawalManagerStorage is IWithdrawalManagerStorage {
    uint256 public override latestConfigId;

    mapping(uint256 => WithdrawalManager.CycleConfig) internal cycleConfigs; // maps config ids to config

    mapping(address => uint256) public override exitCycleId;
    mapping(address => uint256) public override lockedShares;
    mapping(uint256 => uint256) public override totalCycleShares;
}
