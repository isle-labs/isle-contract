// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

abstract contract Events {
    // IsleGlobals events
    event Initialized(address governor_);

    event IsleVaultSet(address indexed previousIsleVault_, address indexed currentIsleVault_);

    event ProtocolPausedSet(address indexed caller_, bool protocolPaused_);

    event ContractPausedSet(address indexed caller_, address indexed contract_, bool contractPaused_);

    event FunctionUnpausedSet(
        address indexed caller_, address indexed contract_, bytes4 indexed sig_, bool functionUnpaused_
    );

    event ProtocolFeeSet(uint24 protocolFee_);

    event ValidReceivableAssetSet(address indexed receivableAsset_, bool isValid_);

    event ValidPoolAssetSet(address indexed poolAsset_, bool isValid_);

    event ValidPoolAdminSet(address indexed poolAdmin_, bool isValid_);

    event PoolConfiguratorSet(address indexed poolAdmin_, address indexed poolConfigurator_);

    event MaxCoverLiquidationSet(uint24 maxCoverLiquidation_);

    event MinCoverSet(uint104 minCover_);

    event PoolLimitSet(uint104 poolLimit_);

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
    event LoanManagerInitialized(address poolAddressesProvider_, address asset_);
    event LoanRequested(uint16 indexed loanId_);
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

    event IsleGlobalsSet(address indexed previousIsleGlobals_, address indexed currentIsleGlobals_);

    // Pool configurator events
    event Initialized(address indexed poolAdmin_, address indexed asset_, address pool_);

    event CoverDeposited(uint256 amount_);

    event CoverWithdrawn(uint256 amount_);

    event AdminFeeSet(uint256 adminFee_);

    event BuyerSet(address indexed buyer_);

    event ValidSellerSet(address indexed seller_, bool isValid_);

    event ValidLenderSet(address indexed lender_, bool isValid_);

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

    event IsleGlobalsUpdated(address indexed oldAddress, address indexed newAddress);
}
