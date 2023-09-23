// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

contract MockImplementation {
    bool public initialized;

    function initialize() external {
        initialized = true;
    }
}
