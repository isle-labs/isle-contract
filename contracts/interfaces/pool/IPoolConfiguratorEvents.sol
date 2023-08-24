// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IPoolConfiguratorEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                    EVENTS
    //////////////////////////////////////////////////////////////////////////*/
    event Initialized(address indexed poolAdmin_, address indexed asset_, address pool_);
    event ConfigurationCompleted();
    event CoverDeposited(uint256 amount_);
    event CoverLiquidated(uint256 toPool_);
    event CoverWithdrawn(uint256 amount_);
    event IsLoanManagerSet(address indexed loanManager_, bool isLoanManager_);
    event LiquidityCapSet(uint256 liquidityCap_);
    event LoanManagerAdded(address indexed loanManager_);
    event ValidSellerSet(address indexed seller_, bool isValid_);
    event ValidBuyerSet(address indexed buyer_, bool isValid_);
    event ValidLenderSet(address indexed lender_, bool isValid_);
    event OpenToPublic(bool isOpenToPublic_);
    event PendingPoolAdminAccepted(address indexed previousPoolAdmin_, address indexed newPoolAdmin_);
    event PendingPoolAdminSet(address indexed previousPoolAdmin_, address indexed newPoolAdmin_);
    event PoolConfigurationComplete();
    event RedeemProcessed(address indexed owner_, uint256 redeemableShares_, uint256 resultingAssets_);
    event RedeemRequested(address indexed owner_, uint256 shares_);
    event SetAsActive(bool active_);
    event SharesRemoved(address indexed owner_, uint256 shares_);
    event WithdrawalManagerSet(address indexed withdrawalManager_);
    event WithdrawalProcessed(address indexed owner_, uint256 redeemableShares_, uint256 resultingAssets_);
    event CollateralLiquidationTriggered(address indexed loan_);
    event CollateralLiquidationFinished(address indexed loan_, uint256 losses_);
}
