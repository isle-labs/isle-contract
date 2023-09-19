// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

abstract contract Events {
    // Pool events
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    // Receivable events
    event AssetCreated(
        address indexed buyer_,
        address indexed seller_,
        uint256 indexed tokenId_,
        uint256 faceAmount_,
        uint256 repaymentTimestamp_
    );

    event LopoGlobalsSet(address indexed previousLopoGlobals_, address indexed currentLopoGlobals_);

    // Pool configurator events
    event CoverDeposited(uint256 amount_);

    event CoverWithdrawn(uint256 amount_);

    event PoolLimitSet(uint256 poolLimit_);

    event AdminFeeSet(uint256 adminFee_);

    event ValidSellerSet(address indexed seller_, bool isValid_);

    event ValidBuyerSet(address indexed buyer_, bool isValid_);

    event ValidLenderSet(address indexed lender_, bool isValid_);

    // WithdrawalManager Events
    event WithdrawalUpdated(address indexed account_, uint256 lockedShares_, uint64 windowStart_, uint64 windowEnd_);
    event WithdrawalProcessed(address indexed account_, uint256 sharesToRedeem_, uint256 assetsToWithdraw_);
    event WithdrawalCancelled(address indexed account_);
    event ConfigurationUpdated(
        uint256 indexed configId_,
        uint64 initialCycleId_,
        uint64 initialCycleTime_,
        uint64 cycleDuration_,
        uint64 windowDuration_
    );
}
