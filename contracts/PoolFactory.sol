// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Adminable } from "./abstracts/Adminable.sol";

import { PoolDeployer } from "./PoolDeployer.sol";
import { PoolAddressesProvider } from "./PoolAddressesProvider.sol";
import { IPoolAddressesProvider } from "./interfaces/IPoolAddressesProvider.sol";

contract PoolFactory is PoolDeployer, Adminable {

    // Stores the mapping of pools
    mapping(string => address) public getPool;

    constructor() {
        transferAdmin(msg.sender);
    }

    function createPool(string memory marketId_, address asset_, string memory name_, string memory symbol_) external returns (address poolAddressesProvider_) {
        // Caching
        address admin_ = admin;

        // Deploy Pool Addresses Provider
        poolAddressesProvider_ = address(new PoolAddressesProvider{salt: keccak256(abi.encode(marketId_))}(marketId_, admin_));

        // Deploy Pool Configurator
        address poolConfigurator_ = deployPoolConfigurator(marketId_, poolAddressesProvider_);

        // Deploy Loan Manager
        address loanManager_ = deployLoanManager(marketId_, poolAddressesProvider_);

        // Deploy Withdrawal Manager
        address withdrawalManager_ = deployWithdrawalManager(marketId_, poolAddressesProvider_);

        // Set implementations
        IPoolAddressesProvider(poolAddressesProvider_).setPoolConfiguratorImpl(poolConfigurator_, asset_, name_, symbol_);
        IPoolAddressesProvider(poolAddressesProvider_).setLoanManagerImpl(loanManager_);
        IPoolAddressesProvider(poolAddressesProvider_).setWithdrawalManagerImpl(withdrawalManager_);

        getPool[marketId_] = poolAddressesProvider_;
    }
}
