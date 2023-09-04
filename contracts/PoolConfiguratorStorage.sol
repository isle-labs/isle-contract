// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { IPoolConfiguratorStorage } from "./interfaces/pool/IPoolConfiguratorStorage.sol";

abstract contract PoolConfiguratorStorage is IPoolConfiguratorStorage {
    address public override asset;
    address public override pool;

    bool public override openToPublic;

    uint256 public override poolCover;
    uint256 public override liquidityCap;
    uint256 public override adminFeeRate;

    mapping(address => bool) public override isBuyer;
    mapping(address => bool) public override isSeller;
    mapping(address => bool) public override isLender;
}
