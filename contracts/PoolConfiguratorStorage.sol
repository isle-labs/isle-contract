// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { IPoolConfiguratorStorage } from "./interfaces/pool/IPoolConfiguratorStorage.sol";

abstract contract PoolConfiguratorStorage is IPoolConfiguratorStorage {
    struct Config {
        bool openToPublic; // Slot 1: bool - 1 byte
        uint24 adminFee; // uint24 - 3 byte: max = 1.6e7 (1600%) / precision: 10e6
        uint32 gracePeriod; // uint32 - 4 byte: max = 4.2e9 (136.19 years)
        uint96 baseRate; // uint96 - 12 byte: max = 7.922816251426434e28 / precision: 10e18
    }

    address public override asset;
    address public override pool;

    Config public override config;

    uint256 public override poolCover;

    mapping(address => bool) public override isBuyer;
    mapping(address => bool) public override isSeller;
    mapping(address => bool) public override isLender;
}
