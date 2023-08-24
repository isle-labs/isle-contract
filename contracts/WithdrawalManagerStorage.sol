// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IWithdrawalManagerStorage } from "./interfaces/IWithdrawalManagerStorage.sol";

abstract contract WithdrawalManagerStorage is IWithdrawalManagerStorage {
    uint256 public override latestConfigId;

    mapping(address => uint256) public override exitCycleId;
    mapping(address => uint256) public override lockedShares;

    mapping(uint256 => uint256) public override totalCycleShares;

    mapping(uint256 => CycleConfig) public override cycleConfigs;
}
