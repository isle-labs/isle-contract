// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IWithdrawalManager } from "./interfaces/IWithdrawalManager.sol";

abstract contract WithdrawalManagerStorage is IWithdrawalManager {

    uint256 public override latestConfigId;

    mapping(address => uint256) public override exitCycleId;
    mapping(address => uint256) public override lockedShares;

    mapping(uint256 => uint256) public override totalCycleShares;

    mapping(uint256 => CycleConfig) public override cycleConfigs;
}
