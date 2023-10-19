// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { PoolConfigurator } from "./libraries/types/DataTypes.sol";

import { IPoolConfiguratorStorage } from "./interfaces/IPoolConfiguratorStorage.sol";

abstract contract PoolConfiguratorStorage is IPoolConfiguratorStorage {
    PoolConfigurator.Config internal _config;

    address public override admin;

    address public override asset;
    address public override pool;
    address public override buyer;

    uint256 public override poolCover;

    mapping(address => bool) public override isSeller;
    mapping(address => bool) public override isLender;
}
