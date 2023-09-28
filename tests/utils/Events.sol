// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

abstract contract Events {
    // Pool events
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(
        address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
    );

    // Receivable events
    event AssetCreated(
        address indexed buyer_,
        address indexed seller_,
        uint256 indexed tokenId_,
        uint256 faceAmount_,
        uint256 repaymentTimestamp_
    );

    event AssetBurned(uint256 indexed tokenId_);

    // LoanManager events
    event LoanApproved(uint16 indexed loanId_);
    event PrincipalOutUpdated(uint128 principalOut_);
    event PaymentAdded(
        uint16 indexed loanId_,
        uint256 indexed paymentId_,
        uint256 protocolFeeRate_,
        uint256 adminFeeRate_,
        uint256 startDate_,
        uint256 dueDate_,
        uint256 newRate_
    );
    event IssuanceParamsUpdated(uint48 indexed domainEnd_, uint256 issuanceRate_, uint112 accountedInterest_);
    event LoanRepaid(uint16 indexed loanId_, uint256 principal_, uint256 interest_);
    event FeesPaid(uint16 indexed loanId_, uint256 adminFee_, uint256 protocolFee_);
    event FundsDistributed(uint16 indexed loanId_, uint256 principal_, uint256 netInterest_);
    event PaymentRemoved(uint16 indexed loanId_, uint256 indexed paymentId_);
    event FundsWithdrawn(uint16 indexed loanId_, uint256 amount_);
    event UnrealizedLossesUpdated(uint128 unrealizedLosses_);
    event LoanImpaired(uint16 indexed loanId_, uint256 newDueDate_);
    event ImpairmentRemoved(uint16 indexed loanId_, uint256 originalPaymentDueDate_);

    event LopoGlobalsSet(address indexed previousLopoGlobals_, address indexed currentLopoGlobals_);

    // Pool configurator events
    event CoverDeposited(uint256 amount_);

    event CoverWithdrawn(uint256 amount_);

    event PoolLimitSet(uint256 poolLimit_);

    event AdminFeeSet(uint256 adminFee_);

    event ValidSellerSet(address indexed seller_, bool isValid_);

    event ValidBuyerSet(address indexed buyer_, bool isValid_);

    event ValidLenderSet(address indexed lender_, bool isValid_);

    event GracePeriodSet(uint256 gracePeriod_);

    event BaseRateSet(uint96 baseRate_);

    event RedeemProcessed(address indexed owner_, uint256 redeemableShares_, uint256 resultingAssets_);

    event SharesRemoved(address indexed owner_, uint256 shares_);

    event OpenToPublicSet(bool isOpenToPublic_);

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

    // PoolAddressesProvider Events

    event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

    event AddressSetAsProxy(
        bytes32 indexed id,
        address indexed proxyAddress,
        address oldImplementationAddress,
        address indexed newImplementationAddress
    );

    event PoolConfiguratorUpdated(address indexed oldAddress, address indexed newAddress);

    event LoanManagerUpdated(address indexed oldAddress, address indexed newAddress);

    event WithdrawalManagerUpdated(address indexed oldAddress, address indexed newAddress);

    event LopoGlobalsUpdated(address indexed oldAddress, address indexed newAddress);
}
