// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { PoolConfigurator } from "./PoolConfigurator.sol";
import { LoanManager } from "./LoanManager.sol";
import { WithdrawalManager } from "./WithdrawalManager.sol";
import { PoolAddressesProvider } from "./PoolAddressesProvider.sol";
import { IPoolAddressesProvider } from "./interfaces/IPoolAddressesProvider.sol";

contract PoolDeployer {

    function deployPoolConfigurator(string memory marketId_, address poolAddressesProvider_) public returns (address poolConfigurator_) {
        return address(new PoolConfigurator{salt: keccak256(abi.encode(marketId_))}(IPoolAddressesProvider(poolAddressesProvider_)));
    }

    function deployLoanManager(string memory marketId_, address poolAddressesProvider_) public returns (address loanManager_) {
        return address(new LoanManager{salt: keccak256(abi.encode(marketId_))}(IPoolAddressesProvider(poolAddressesProvider_)));
    }

    function deployWithdrawalManager(string memory marketId_, address poolAddressesProvider_) public returns (address withdrawalManager_) {
        return address(new WithdrawalManager{salt: keccak256(abi.encode(marketId_))}(IPoolAddressesProvider(poolAddressesProvider_)));
    }
}
