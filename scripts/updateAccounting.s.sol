// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@forge-std/console2.sol";

import { ILoanManager } from "../contracts/interfaces/ILoanManager.sol";
import { IPoolAddressesProvider } from "../contracts/interfaces/IPoolAddressesProvider.sol";

import { Loan } from "../contracts/libraries/types/DataTypes.sol";

import { BaseScript } from "./Base.s.sol";

contract UpdateAccounting is BaseScript {
    function run(IPoolAddressesProvider poolAddressesProvider_) public broadcast(governor) {
        ILoanManager loanManager_ = ILoanManager(poolAddressesProvider_.getLoanManager());
        loanManager_.updateAccounting();
    }
}
