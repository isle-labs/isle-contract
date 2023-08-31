// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

abstract contract Events {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
}
