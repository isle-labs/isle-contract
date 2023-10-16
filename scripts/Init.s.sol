// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { Solarray } from "solarray/Solarray.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { Receivable, Loan } from "../contracts/libraries/types/DataTypes.sol";

import { IPoolAddressesProvider } from "../contracts/interfaces/IPoolAddressesProvider.sol";
import { IReceivable } from "../contracts/interfaces/IReceivable.sol";
import { IPoolConfigurator } from "../contracts/interfaces/IPoolConfigurator.sol";
import { ILoanManager } from "../contracts/interfaces/ILoanManager.sol";
import { IIsleGlobals } from "../contracts/interfaces/IIsleGlobals.sol";
import { IPool } from "../contracts/interfaces/IPool.sol";

import { IERC20Mint } from "./contracts/ERC20Mint.sol";
import { BaseScript } from "./Base.s.sol";

/// @notice Initializes the pool with deposits and loans.
contract Init is BaseScript {
    function run(IReceivable receivable_, IPoolAddressesProvider poolAddressesProvider_) public {
        IPoolConfigurator poolConfigurator_ = IPoolConfigurator(poolAddressesProvider_.getPoolConfigurator());
        IPool pool_ = IPool(poolConfigurator_.pool());
        ILoanManager loanManager_ = ILoanManager(poolAddressesProvider_.getLoanManager());

        initPoolWithGovernor(poolConfigurator_);
        initPoolWithPoolAdmin(poolConfigurator_);

        deposit(pool_);

        uint256[] memory tokenIds_ = initReceivables(receivable_);
        uint16[] memory loanIds_ = approveLoans(loanManager_, receivable_, tokenIds_, tokenIds_.length - 1);

        fundLoans(loanManager_, loanIds_, loanIds_.length - 1);
        withdrawFunds(loanManager_, loanIds_, loanIds_.length - 2);
    }

    function initPoolWithPoolAdmin(IPoolConfigurator poolConfigurator_) internal broadcast(poolAdmin) {
        poolConfigurator_.setAdminFee(0.1e6);
        poolConfigurator_.setBuyer(buyer);
        poolConfigurator_.setValidSeller(seller, true);
        poolConfigurator_.setOpenToPublic(true);

        address asset_ = poolConfigurator_.asset();
        IERC20Mint(asset_).mint({ beneficiary: poolAdmin, amount: 100e18 });
        IERC20(asset_).approve({ spender: address(poolConfigurator_), amount: 100e18 });
        poolConfigurator_.depositCover(100e18);
    }

    function initPoolWithGovernor(IPoolConfigurator poolConfigurator_) internal broadcast(governor) {
        poolConfigurator_.setPoolLimit(100_000_000e18);
        poolConfigurator_.setMinCover(10e18);
    }

    function deposit(IPool pool_) internal broadcast(lender) {
        address asset_ = pool_.asset();
        uint256 amount_ = 1_000_000e18;

        // Mint 10k assets to the sender.
        IERC20Mint(asset_).mint({ beneficiary: lender, amount: amount_ });
        IERC20(asset_).approve({ spender: address(pool_), amount: amount_ });

        // Deposit all 10k assets in the pool.
        pool_.deposit({ assets: amount_, receiver: lender });

        // Request a tenth of it back.
        pool_.requestRedeem({ shares_: amount_ / 10, owner_: lender });
    }

    function initReceivables(IReceivable receivable_) internal broadcast(buyer) returns (uint256[] memory tokenIds_) {
        uint256[] memory totalAmounts_ =
            Solarray.uint256s(0.1e18, 1e18, 100e18, 1000e18, 5000e18, 25_000e18, 100_000e18);
        uint256[] memory totalDurations_ =
            Solarray.uint256s(4 weeks, 8 weeks, 12 weeks, 16 weeks, 6 weeks, 20 weeks, 24 weeks);
        tokenIds_ = new uint256[](totalAmounts_.length);

        for (uint32 i = 0; i < totalAmounts_.length; ++i) {
            uint256 tokenId_ = receivable_.createReceivable(
                Receivable.Create({
                    faceAmount: totalAmounts_[i],
                    repaymentTimestamp: block.timestamp + totalDurations_[i],
                    seller: seller,
                    buyer: buyer,
                    currencyCode: 840
                })
            );
            tokenIds_[i] = tokenId_;
        }
    }

    function approveLoans(
        ILoanManager loanManager_,
        IReceivable receivable_,
        uint256[] memory tokenIds_,
        uint256 length_
    )
        internal
        broadcast(buyer)
        returns (uint16[] memory loanIds_)
    {
        loanIds_ = new uint16[](length_);

        for (uint256 i = 0; i < length_; i++) {
            Receivable.Info memory info_ = receivable_.getReceivableInfoById(tokenIds_[i]);
            uint16 loanId_ = loanManager_.approveLoan({
                collateralAsset_: address(receivable_),
                receivablesTokenId_: tokenIds_[i],
                gracePeriod_: 3 days,
                principalRequested_: info_.faceAmount * 9 / 10,
                rates_: [uint256(0.12e6), uint256(0.06e6)] // interestRate: 12%, lateInterestPremiumRate: 6%
             });
            loanIds_[i] = loanId_;
        }
    }

    function fundLoans(
        ILoanManager loanManager_,
        uint16[] memory loanIds_,
        uint256 length_
    )
        internal
        broadcast(poolAdmin)
    {
        for (uint256 i = 0; i < length_; i++) {
            loanManager_.fundLoan({ loanId_: loanIds_[i] });
        }
    }

    function withdrawFunds(
        ILoanManager loanManager_,
        uint16[] memory loanIds_,
        uint256 length_
    )
        internal
        broadcast(seller)
    {
        for (uint256 i = 0; i < length_; i++) {
            Loan.Info memory info_ = loanManager_.getLoanInfo(loanIds_[i]);

            IERC721(info_.collateralAsset).approve(address(loanManager_), info_.collateralTokenId);

            loanManager_.withdrawFunds({ loanId_: loanIds_[i], destination_: seller, amount_: info_.drawableFunds });
        }
    }
}
