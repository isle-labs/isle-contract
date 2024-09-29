// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import "@forge-std/console2.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ILoanManager } from "../contracts/interfaces/ILoanManager.sol";
import { IPoolConfigurator } from "../contracts/interfaces/IPoolConfigurator.sol";
import { IPoolAddressesProvider } from "../contracts/interfaces/IPoolAddressesProvider.sol";
import { IReceivable } from "../contracts/interfaces/IReceivable.sol";
import { IERC20Mint } from "./contracts/ERC20Mint.sol";

import { Loan, Receivable } from "../contracts/libraries/types/DataTypes.sol";

import { BaseScript } from "./Base.s.sol";

contract createLoan is BaseScript {
    function run(IPoolAddressesProvider poolAddressesProvider_, IReceivable receivable_) public broadcast(buyer) {
        ILoanManager loanManager_ = ILoanManager(poolAddressesProvider_.getLoanManager());

        uint256 tokenId_ = receivable_.createReceivable(
            Receivable.Create({
                faceAmount: 1000e18,
                repaymentTimestamp: 1_705_276_800, // 2024.1.15
                seller: seller,
                buyer: buyer,
                currencyCode: 840
            })
        );

        Receivable.Info memory info_ = receivable_.getReceivableInfoById(tokenId_);
        uint16 loanId_ = loanManager_.requestLoan({
            receivableAsset_: address(receivable_),
            receivablesTokenId_: tokenId_,
            gracePeriod_: 3 days,
            principalRequested_: info_.faceAmount * 9 / 10,
            rates_: [uint256(0.12e6), uint256(0.06e6)] // interestRate: 12%, lateInterestPremiumRate: 6%
         });

        console2.log("Created loan: %d", loanId_);
    }
}
