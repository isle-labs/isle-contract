// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IPoolConfiguratorLike {
    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);
    function getEscrowParams(address owner_, uint256 shares_) external view returns (uint256 escrowShares_, address destination_);
    function requestRedeem(uint256 escrowShares_, address owner_, address sender_) external;
    function requestWithdraw(uint256 escrowShares_, uint256 assets_, address owner_, address sender_) external;

    function maxDeposit(address receiver_) external view returns (uint256 maxAssets_);
    function maxMint(address receiver_) external view returns (uint256 maxShares_);
    function maxRedeem(address owner_) external view returns (uint256 maxShares_);
    function maxWithdraw(address owner_) external view returns (uint256 maxAssets_);

    function previewRedeem(uint256 assets_) external view returns (uint256 shares_);
    function previewWithdraw(uint256 shares_) external view returns (uint256 assets_);

    function unrealizedGains() external view returns (uint256 unrealizedGains_);
    function unrealizedLosses() external view returns (uint256 unrealizedLosses_);
}

interface IGlobalsLike {
    function governor() external view returns (address governor_);
    function isFunctionPaused(bytes4 sig_) external view returns (bool isFunctionPaused_);
    function isPoolAsset(address asset_) external view returns (bool isPoolAsset_);
    function isPoolAdmin(address asset_) external view returns (bool isPoolAdmin_);
    function isPoolDeployer(address poolDeployer_) external view returns (bool isPoolDeployer_);
    function lopoTreasury() external view returns (address lopoTreasury_);
    function maxCoverLiquidationPercent(address poolConfigurator_) external view returns (uint256 maxCoverLiquidationPercent_);
    function minCoverAmount(address poolConfigurator_) external view returns (uint256 minCoverAmount_);
    function ownedPoolConfigurator(address poolAdmin_) external view returns (address poolConfigurator_);
    function securityAdmin() external view returns (address securityAdmin_);
    function transferOwnedPoolConfigurator(address fromPoolAdmin_, address toPoolAdmin_) external;
}

interface IERC20Like {
    function allowance(address owner_, address spender_) external view returns (uint256 allowance_);
    function balanceOf(address account_) external view returns (uint256 balance_);
    function totalSupply() external view returns (uint256 totalSupply_);
    function transferFrom(address owner_, address recipient_, uint256 amount_) external returns (bool success_);
    function approve(address spender_, uint256 amount_) external returns (bool success_);
}

interface IWithdrawalManagerLike {
    function addShares(uint256 shares_, address owner_) external;
    function isInExitWindow(address owner_) external view returns (bool isInExitWindow_);
    function lockedLiquidity() external view returns (uint256 lockedLiquidity_);
    function lockedShares(address owner_) external view returns (uint256 lockedShares_);
    function previewRedeem(address owner_, uint256 shares) external view returns (uint256 redeemableShares, uint256 resultingAssets_);
    function previewWithdraw(address owner_, uint256 assets_) external view returns (uint256 redeemableAssets_, uint256 resultingShares_);
    function processExit(uint256 shares_, address account_) external returns (uint256 redeemableShares_, uint256 resultingAssets_);
    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);
}

interface ILoanManagerLike {

    function assetsUnderManagement() external view returns (uint256 assetsUnderManagement_);
    function triggerDefault(address loan_, address liquidatorFactory_)
        external
        returns (bool liquidationComplete_, uint256 remainingLosses_, uint256 platformFees_);
    function unrealizedLosses() external view returns (uint256 unrealizedLosses_);
    function unrealizedGains() external view returns (uint256 unrealizedGains_);
}

interface ILoanLike {
    function lender() external view returns (address lender_);
}

interface IPoolAdminCoverLike {
    function moveFunds(uint256 amount_, address recipient_) external;
}

interface IPoolLike is IERC20Like {

    function convertToExitShares(uint256 assets_) external view returns (uint256 shares_);

    function previewDeposit(uint256 assets_) external view returns (uint256 shares_);

    function previewMint(uint256 shares_) external view returns (uint256 assets_);

}
