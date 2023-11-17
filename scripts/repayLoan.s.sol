// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import "@forge-std/console2.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ILoanManager } from "../contracts/interfaces/ILoanManager.sol";
import { IPoolConfigurator } from "../contracts/interfaces/IPoolConfigurator.sol";
import { IPoolAddressesProvider } from "../contracts/interfaces/IPoolAddressesProvider.sol";
import { IERC20Mint } from "./contracts/ERC20Mint.sol";

import { Loan } from "../contracts/libraries/types/DataTypes.sol";

import { BaseScript } from "./Base.s.sol";

contract repayLoan is BaseScript {
    function run(IPoolAddressesProvider poolAddressesProvider_, uint16 loanId_) public broadcast(buyer) {
        (uint256 principal_, uint256 interest_) =
            ILoanManager(poolAddressesProvider_.getLoanManager()).getLoanPaymentBreakdown(loanId_);

        console2.log("id: %s, principal: %d, interest: %d", loanId_, principal_, interest_);
        IPoolConfigurator poolConfigurator_ = IPoolConfigurator(poolAddressesProvider_.getPoolConfigurator());
        address asset_ = poolConfigurator_.asset();

        IERC20Mint(asset_).mint({ beneficiary: buyer, amount: principal_ + interest_ });
        address loanManager_ = poolAddressesProvider_.getLoanManager();

        IERC20(asset_).approve({ spender: address(loanManager_), amount: principal_ + interest_ });
        ILoanManager(loanManager_).repayLoan(loanId_);
    }
}
