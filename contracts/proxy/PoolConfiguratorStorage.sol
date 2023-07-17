// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { IPoolConfiguratorStorage } from "../interfaces/pool/IPoolConfiguratorStorage.sol";

abstract contract PoolConfiguratorStorage is IPoolConfiguratorStorage {
    uint256 internal _locked;

    address public override poolAdmin;
    address public override pendingPoolAdmin;

    address public override asset;
    address public override pool;

    address public override poolAdminCover;
    address public override withdrawalManager;

    bool public override active;
    bool public override configured;
    bool public override openToPublic;

    uint256 public override liquidityCap;

    mapping(address => bool) public override isLoanManager;
    mapping(address => bool) public override isValidLender;

    address[] public override loanManagerList;
}
