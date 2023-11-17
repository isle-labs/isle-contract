// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import "@forge-std/console2.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IIsleGlobals } from "../contracts/interfaces/IIsleGlobals.sol";
import { ILoanManager } from "../contracts/interfaces/ILoanManager.sol";
import { IPoolConfigurator } from "../contracts/interfaces/IPoolConfigurator.sol";
import { IPoolAddressesProvider } from "../contracts/interfaces/IPoolAddressesProvider.sol";
import { IERC20Mint } from "./contracts/ERC20Mint.sol";

import { Loan } from "../contracts/libraries/types/DataTypes.sol";

import { BaseScript } from "./Base.s.sol";

contract repayLoan is BaseScript {
    function run(IIsleGlobals isleGlobals_) public broadcast(governor) {
        isleGlobals_.setIsleVault(vault);
    }
}
