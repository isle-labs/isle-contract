// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../../contracts/PoolConfigurator.sol";

contract MockPoolConfigurator is PoolConfigurator {
    constructor(IPoolAddressesProvider provider_) PoolConfigurator(provider_) { }

    function maxDeposit(address receiver_) external view override returns (uint256) {
        return type(uint256).max;
    }
}
